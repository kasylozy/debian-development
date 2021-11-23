#!/bin/bash
set -e

clear

configurationSSH () {
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
    sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords yes/" /etc/ssh/sshd_config
    passwd root -d
    systemctl restart sshd
}

installRequirements () {
  if [ ! -f "/usr/bin/vim" ]; then
    apt install -y wget git open-vm-{tools,tools-desktop} vim man
  fi
}

addLineSharedFstab () {
  if ! grep -q ".host:/" /etc/fstab; then
    echo ".host:/ /mnt/hgfs       fuse.vmhgfs-fuse        auto,allow_other        0       0" >> /etc/fstab
  fi
}

sharedMissingFolders () {
  clear
  echo -e "Vous devez ajouter au moin un dossier partagé\n"
  exit 0
}

endScriptErrorSharedFolders () {
  clear
  echo -e "Le script ces arrêté puis que le dossier demander n'existe pas
Vérifié la saisie et relancé le script de nouveau
"
exit 0
}

syncSharedDirectory () {
  directoryWeb=/var/www
  directoryShared=`ls /mnt/ | wc -l`
  hgfs=/mnt/hgfs
  if [ $directoryShared -eq 0 ]; then
    sharedMissingFolders
  fi

  declare -a indexShareDirectory
  indexCount=0
  countSharedDirectory=`ls /mnt/hgfs/ | wc -l`
  if [ $countSharedDirectory -gt 1 ]; then
    clear
    echo -e "Voici la liste de vos dossier partagé avec leur position"
    for folder in `ls /mnt/hgfs`; do
      echo "${indexCount} : ${folder}"
      indexShareDirectory[$indexCount]=$folder
      indexCount=${indexCount+1}
    done

    read -p "Entrez le numéro du dossier web : " SHAREDCHOICE
    if ! echo $SHAREDCHOICE | grep -x -E '[[:digit:]]+' &>/dev/null; then
      endScriptErrorSharedFolders
    else
      if [ "${SHAREDCHOICE}" -le "${indexCount}" ]; then
        rm -Rf ${directoryWeb}
        ln -s /mnt/hgfs/${indexShareDirectory[$SHAREDCHOICE]} ${directoryWeb}
      else
        endScriptErrorSharedFolders
      fi
    fi
  else
    directoryAsShared=`ls /mnt/hgfs`
    rm -Rf ${directoryWeb}
    ln -s /mnt/hgfs/${directoryAsShared} ${directoryWeb}
  fi
}

sslCertificateLocal () {
  sslDirectory=/etc/ssl
  if [ ! -f "${sslDirectory}/dev.local.csr" ]; then
    openssl req -new -newkey rsa:4096 -nodes \
      -keyout ${sslDirectory}/dev.local.key -out ${sslDirectory}/dev.local.csr \
      -subj "/C=FR/ST=kasylozy/L=Montpelier/O=Dis/CN=dev.local"

    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
      -subj "/C=FR/ST=kasylozy/L=Montpelier/O=Dis/CN=dev.local" \
      -keyout ${sslDirectory}/dev.local.key  -out ${sslDirectory}/dev.local.cert
  fi
}

installApache2 () {
  if [ ! -d "/etc/apache2" ]; then
    apt install apache2 -y
    cat > /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
  #ServerName www.example.com
  ServerAdmin webmaster@localhost
  DocumentRoot /var/www
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
  <Directory /var/www>
    Options +Indexes +FollowSymLinks
    AllowOverride All
  </Directory>
</VirtualHost>
EOF

    cat > /etc/apache2/sites-available/default-ssl.conf <<EOF
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
  ServerAdmin webmaster@localhost

  DocumentRoot /var/www

  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined

  SSLEngine on
  SSLCertificateFile      /etc/ssl/dev.local.cert
  SSLCertificateKeyFile /etc/ssl/dev.local.key

  <FilesMatch "\.(cgi|shtml|phtml|php)$">
    SSLOptions +StdEnvVars
  </FilesMatch>

  <Directory /usr/lib/cgi-bin>
    SSLOptions +StdEnvVars
  </Directory>

  </VirtualHost>
</IfModule>
EOF
    a2enmod rewrite
    a2ensite default-ssl
    a2enmod ssl
  fi
  systemctl stop apache2
}

installNginx () {
  if [ ! -d "/etc/nginx" ]; then
    apt install -y ca-certificates apt-transport-https
    wget -q https://packages.sury.org/nginx/apt.gpg -O- | apt-key add -
    echo "deb https://packages.sury.org/nginx/ stretch main" | tee /etc/apt/sources.list.d/nginx.list
    apt update && apt install nginx-full -y
    
    cat > /etc/nginx/nginx.conf <<EOF
user  www-data;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status $body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    client_max_body_size 2G;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
  listen 8081;
  server_name _;
  return 301 https://\$host\$request_uri;
}

server {
  listen       8080;
  listen 8081 default_server ssl;
  ssl_certificate     /etc/ssl/dev.local.cert;
  ssl_certificate_key /etc/ssl/dev.local.key;
  ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers         HIGH:!aNULL:!MD5;
  server_name  localhost;
  root /var/www;
  index index.php index.html index.htm;
  autoindex on;
  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php$ {
    try_files \$uri =404;
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
  }

  location ~ /\.ht {
    deny  all;
  }
}
EOF
  fi

  systemctl restart apache2
  systemctl restart nginx
}



installPhp () {
  if [ ! -d "/etc/php" ]; then
    apt install -y \
      libapache2-mod-php7.4 \
      libphp7.4-embed \
      php7.4 \
      php-zmq \
      php7.4-bcmath \
      php7.4-bz2 \
      php7.4-cgi \
      php7.4-cli \
      php7.4-common \
      php7.4-curl \
      php7.4-dba \
      php7.4-enchant \
      php7.4-fpm \
      php7.4-gd \
      php7.4-gmp \
      php7.4-imap \
      php7.4-interbase \
      php7.4-intl \
      php7.4-json \
      php7.4-ldap \
      php7.4-mbstring \
      php7.4-mysql \
      php7.4-odbc \
      php7.4-opcache \
      php7.4-pgsql \
      php7.4-phpdbg \
      php7.4-pspell \
      php7.4-readline \
      php7.4-snmp \
      php7.4-soap \
      php7.4-sqlite3 \
      php7.4-sybase \
      php7.4-tidy \
      php7.4-xml \
      php7.4-xmlrpc \
      php7.4-xsl \
      php7.4-zip \
      php-xdebug

    a2enmod php7.4
    systemctl restart apache2
  fi
  for file in `find /etc/php -type f -name "php.ini"`; do
		sed -i "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/" ${file}
		sed -i "s/display_errors = Off/display_errors = On/" ${file}
		sed -i "s/display_startup_errors = Off/display_startup_errors = On/" ${file}
		sed -i "s/log_errors = On/log_errors = Off/" ${file}
		sed -i "s/post_max_size = 8M/post_max_size = 8G/" ${file}
		sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 8G/" ${file}
		#sed -i "s/;extension=/extension=/" ${file}
	done
}

function installRuby () {
	if [ ! -f "/usr/bin/ruby" ]; then
		apt install -y ruby-full
	fi
}

function installComposer () {
  composerDirectory=/usr/local/bin/composer  
	if [ ! -f "${composerDirectory}" ]; then
		wget https://getcomposer.org/download/2.1.12/composer.phar
		mv composer.phar ${composerDirectory}
		chmod 777 ${composerDirectory}
	fi
}

function installMariadb () {
	if [ ! -f "/usr/bin/mysql" ]; then
		apt-get install -y software-properties-common dirmngr apt-transport-https
		apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
		add-apt-repository 'deb [arch=amd64,i386,arm64,ppc64el] https://ftp.osuosl.org/pub/mariadb/repo/10.6/debian bullseye main'
		apt-get update
		apt install -y mariadb-server mariadb-client
	fi
	
  check=`mysql -uroot -proot -e "select host from mysql.user where user='root' and host='%';"`
  if [ -z "${check}" ]; then
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
		systemctl enable --now mariadb
		mysql -uroot -proot -e "create user root@'%' identified by '';"
		mysql -uroot -proot -e "grant all privileges on *.* to root@'%';"
  fi
	
	sed -i "s/127\.0\.0\.1/0\.0\.0\.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

	systemctl restart mariadb
}

function installPostfix () {
  postfixConfig=/etc/postfix/main.cf
  if [ ! -f "${postfixConfig}" ]; then
	  DEBIAN_FRONTEND=noninteractive apt-get -y install postfix
cat > ${postfixConfig} <<EOF
smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level=may
smtp_tls_CApath=/etc/ssl/certs
smtp_tls_security_level=may
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = debian.localdomain
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname, debian, localhost.localdomain, , localhost
relayhost = 0.0.0.0:1025
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = all
EOF
    systemctl restart postfix
  fi
}

function installDocker () {
	if [ ! -d "/etc/docker" ]; then
		apt update
		apt-get install \
			ca-certificates \
			curl \
			gnupg \
			lsb-release -y
		curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
		$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
		apt-get update
		apt-get install docker-ce docker-ce-cli containerd.io -y
	fi
}

function configureMailDev () {
  if ! docker ps | grep mail; then
	  docker run -d --restart unless-stopped -p 1080:1080 -p 1025:1025 dominikserafin/maildev:latest
  fi
}

installNpm () {
  if [ ! -f "/usr/bin/npm" ]; then
    apt install npm -y
  fi
}

function installFinish () {
	clear
	echo ""
	echo "L'installation est terminée vous pouvez utiliser votre serveur de développement"
	echo "Apache port 80"
	echo "Nginx port 8080"
	echo "Nginx SSL port 8081"
	echo "Maildev port 1080"
	echo "Username mysql : root"
	echo "Password mysql : Aucun laissez vide"
	echo ""
	echo "Votre ip public:"
	ifconfig ens33 | awk '/inet / {print $2}' | cut -d ':' -f2
	echo ""
	echo ""
}

main () {
  configurationSSH
  installRequirements
  addLineSharedFstab
  syncSharedDirectory
  sslCertificateLocal
  installApache2
  installNginx
  installPhp
  installRuby
  installComposer
  installMariadb
  installPostfix
  installDocker
  configureMailDev
  installNpm
  installFinish
}

main
