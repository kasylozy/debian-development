# Script de machine virtuel VMware Debian

### Voici le déroulement de l'installation


# (1)
#### Voici comment paramètrer un dossier partagé

> Rendez-vous sur VMware Workstation > Faites clique droit sur votre VM et cliquez sur Settings...
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/4.png?raw=true)


# (2)

> Cliquez sur  Opens puis sur Shared Folders ( Disabled )
> 
>  ![](https://github.com/kasylozy/debian-development/blob/master/pictures/5.PNG?raw=true)

# (3)
> Cliquez sur Always Enabled puis cliquez sur Add....
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/6.PNG?raw=true)

# (4)
> Appyez sur next >
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/7.PNG?raw=true)

# (5)
> Appyez sur Browse...
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/8.PNG?raw=true)

# (6)
> Sélectionnez votre dossier ( le nom n'est pas important ici )
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/9.PNG?raw=true)

# (7)
> Le programme chargera un nom par défaut 
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/10.PNG?raw=true)

# (8)
> Changez le nom pour web ( Ce nom est utilisé par le script pour le dossier partagé avec apache port 80 et nginx port 8080)
>
![](https://github.com/kasylozy/debian-development/blob/master/pictures/11.PNG?raw=true)

# (9)
> À cette étape la case Enable this share devrait être coché si cela n'est pas le cas cochez-là
>
![](https://github.com/kasylozy/debian-development/blob/master/pictures/12.PNG?raw=true)


# (10)

# Le lancement du script

> Voici comment l'installer
>
> Copiez-là ligne qui suit et collé la dans votre terminal puis tappez entrer
``` 
apt install wget -y; wget https://raw.githubusercontent.com/kasylozy/debian-development/master/install.sh; chmod +x install.sh; /bin/bash install.sh
```

![enter image description here](https://github.com/kasylozy/debian-development/blob/master/pictures/1.PNG?raw=true)

# (11)
> Le script comment l'installation
> 
> ![enter image description here](https://github.com/kasylozy/debian-development/blob/master/pictures/2.PNG?raw=true)

## L'installation est terminée
> 
> ![](https://github.com/kasylozy/debian-development/blob/master/pictures/22.PNG?raw=true)

### Vous pouvez récupérer l'adresse ip de votre machine par la commande suivante

> Commande : ```hostname -I```
> 
>Mon adresse ip est  :  192.168.75.136
>
![](https://github.com/kasylozy/debian-development/blob/master/pictures/55.PNG?raw=true)
