#!/bin/bash
set -e

installRequirements () {
  if [ ! -f "/usr/bin/wget" ]; then
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
      syncSharedDirectory
      exit 0
    else
      if [ "${SHAREDCHOICE}" -le "${indexCount}" ]; then
	rm -Rf ${directoryWeb}
	ln -s /mnt/hgfs/${indexShareDirectory[$SHAREDCHOICE]} ${directoryWeb}
      else
	syncSharedDirectory
	exit 0
      fi
    fi
  else
    directoryAsShared=`ls /mnt/hgfs`
    rm -Rf ${directoryWeb}
    ln -s /mnt/hgfs/${directoryAsShared} ${directoryWeb}
  fi
}

main () {
  installRequirements
  addLineSharedFstab
  syncSharedDirectory
}

main

