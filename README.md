# VM Vmware de developpement sur Debian 11

wget, git, vim, apache2, nginx, PHP 7.4, Ruby, Composer, Mariadb, Postfix, Docker, MailDev, SSL 

# Le lancement du script

> Voici comment l'installer
>
> Copiez-là ligne qui suit et collé la dans votre terminal puis tappez entrer
``` 
apt install wget -y; wget https://raw.githubusercontent.com/kasylozy/debian-development/master/install.sh; chmod +x install.sh; /bin/bash install.sh;rm -f install.sh
```

## Le script ne voit pas mon dossier partagé
Deux raison peuvent être à l'origine

1 : Vous avez mis le dossier partagé avant l'installation de debian, retournée dans share faites disabled OK, et réactivé le partage et OK attendé 3 secondes et relancé le script

2 : Vous n'avez pas partagé de dossier, partagez-en un et relancé le script :)
