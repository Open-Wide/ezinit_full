#!/bin/bash

# INCLUDES
source generic_functions.sh
source ezinit_header.sh

# start script
echo -e "$GREEN ********* start : ezinit.sh *************** $ENDCOLOR"

# verifie que le fichier $EZSOURCE existe et teste si est un fichier ou un dossier
# @TODO : si le fichier source n'existe pas le demander en prompt 
fileordir $EZSOURCE
TEST=$?
if [ "$TEST" == 99 ]; then
	exit 101;
elif [ "$TEST" != 1 ] && [ "$TEST" == 2 ]; then
	echo -e "$RED la fonction 'fileordir' retourne une valeur inattendu : $TEST $ENDCOLOR"
	exit 900;
fi
SOURCETYPE=$TEST

# se deplace dans le dossier $WEBPATH
cd $WEBPATH

# si $EZSOURCE est un fichier compressé le decompresse après avoir determiné son extension
if [ "$SOURCETYPE" == 1 ]; then
	# retrouve l'extension du fichier
	EXT=$(fileextension $EZSOURCE) 
	echo -e "$BLUE info : extension du fichier : ${EXT} $ENDCOLOR"

	# crée un dossier temp et se deplace à l'interieur
	mkdir temp/
	cd temp/

	# decompresse l'archive
	uncompress $EZSOURCE $EXT
	TEST=$?
	# si ce n'est pas un archive valable efface le dossier temp et fin du script
	if [ "$TEST" != 0 ]; then
		cd $WEBPATH; rm -rf temp/
		exit 102;
	fi

	# assigne à la variable $EZPROJ le nom du dossier extrait
	ls -1 . > ../filelist
	EZPROJ=`cat ../filelist`
	echo -e "$BLUE info : nom du dossier extrait : ${EZPROJ} $ENDCOLOR"

	# deplace le dossier extrait dans $WEBPATH et efface les fichiers temporaires
	mv $EZPROJ $WEBPATH
	cd $WEBPATH; rm -rf temp/; rm -f filelist

# si $EZSOURCE est un dossier assign à la variable $EZPROJ son chemin	
elif [ "$SOURCETYPE" == 2 ]; then
	EZPROJ=$EZSOURCE
fi

# demande le nom à donner au projet
read -p 'nom du projet? : ' PROJNAME

# renomme et deplace le dossier source avec le nom du projet donnée en prompt
mv -v $EZPROJ $WEBPATH$PROJNAME

# liste les fichiers dans $WEBPATH pour verification
ls -la $WEBPATH

# fixe droits et proprietaire:group
cd $WEBPATH
sudo chown -R $USER:www-data $WEBPATH$PROJNAME
sudo chmod -R 775 $WEBPATH$PROJNAME

# demande si il doit crée un lien symbolic dans /var/www/
goornotgo "créer un lien symbolic dans /var/www/ ?"
GO=$?
if [ "$GO" == 0 ]; then
	sudo ln -sv $WEBPATH$PROJNAME /var/www/$PROJNAME
	ls -la /var/www/
fi

# demande si il faut créer la base de donné pour le projet
# si on decide de ne pas la créer purge termine le script
goornotgo "créer la base de données pour le projet ? "
GO=$?
if [ "$GO" == 1 ] || [ "$GO" == 99 ]; then
{
	echo -e "$GREEN La base de donné devra être crée manuellement."
	echo -e "********* end : ezvhinit.sh *************** $ENDCOLOR"
	exit 100;
}
fi

# CRÉE LA BASE DONNÉ MYSQL POUR LE PROJET
# @TODO : remplacé le 'temp_ezinitdb.sql' par une variable
# se deplace dans le dossier $WORKPATH
cd $WORKPATH

# copie le fichier $MODELEMYSQL si existe
# sinon demande le nom du fichier modele mysql et son chemin
if [ -e $MODELEMYSQL ]; then
	sudo cp -f $MODELEMYSQL temp_ezinitdb.sql
else
{
	# demande un chemin pour le modele mysql et copie le fichier donné en prompt si existe
	# sinon affiche un message d'erreur et quitte le script
	read -p 'chemin et nom du modele mysql (create database) : ' MODELEMYSQL
	if [ -e "$MODELEMYSQL" ]; then
		sudo cp -f $MODELEMYSQL temp_ezinitdb.sql
	else
	{
		echo -e "$RED je n'arrive pas à trouver $MODELEMYSQL"
		echo -e "La base de donné devra être crée manuellement ! $ENDCOLOR"
		echo -e "$GREEN ********* end : ezinit.sh *************** $ENDCOLOR"
		exit 100;
	}
	fi
}
fi

# remplace les occurences '{NAME}' par le nom du projet
sudo sed -i "s/{NAME}/$PROJNAME/g" temp_ezinitdb.sql

# ouvre le fichier sql crée pour verifier que tout va bien ;)
sudo gedit temp_ezinitdb.sql & 

# attend que la verification manuelle soit terminé (fermeture de gedit)
wait

# se connecte à mysql et execute le create database statement
# @TODO permettre la personalisation de la commande
mysql -u root < temp_ezinitdb.sql >> result.temp
mysql -u root -e "show databases;" >> result.temp
# verifie
gedit result.temp &

wait

rm -fv temp_ezinitdb.sql result.temp

# se deplace dans le dossier sites-availables
cd /etc/apache2/sites-available

# definie le nom du vhost
VHOST="$PROJNAME.local"

# copie le fichier $MODELEVH si existe
# sinon demande le nom du ficheir vhost modele et son chemin
if [ -e $MODELEVH ]; then
	sudo cp -f $MODELEVH $VHOST
else
{
	# copie le fichier donné en prompt si existe
	# sinon affiche un message d'erreur et quitte le script
	read -p 'chemin et nom du modele vhost : ' MODELEVH
	if [ -e "$MODELEVH" ]; then
		sudo cp -f $MODELEVH $VHOST
	else
	{
		echo -e "$RED je n'arrive pas à trouver $MODELEVH"
		echo -e "********* end : ezvhinit.sh *************** $ENDCOLOR"
		exit 101;
	}
	fi
}
fi

# remplace les occurences '{PATH}' par le chemin des projets web
sudo sed -i "s@{PATH}@$WEBPATH@g" $VHOST
# remplace les occurences '{NAME}' par le nom du projet
sudo sed -i "s/{NAME}/$PROJNAME/g" $VHOST

# ouvre le fichier vhost crée pour verifier que tout va bien ;)
sudo gedit $VHOST & 

# attend que la verification manuelle du vhost soit terminé (fermeture de gedit)
wait

# demande si il faut continuer ou pas
# si on decide de ne pas continuer purge les changements effectués et quitte le script
goornotgo
GO=$?
if [ "$GO" == 1 ] || [ "$GO" == 99 ]; then
{
	sudo rm -fv $VHOST
	echo -e "$GREEN tous les changements effectuées on été annullés"
	echo -e "********* end : ezvhinit.sh *************** $ENDCOLOR"
	exit 100;
}
fi

# enable le site
sudo a2ensite $VHOST
# reload apache config
sudo /etc/init.d/apache2 reload

# met à jour le fichier /etc/hosts
echo -e "\r$ADRESSEIP    $VHOST\r$ADRESSEIP    admin.$VHOST" | sudo tee -a /etc/hosts
# ouvre le /etc/hosts pour verification
sudo gedit /etc/hosts&
# attend la verification
wait

# restart apache
sudo /etc/init.d/apache2 restart

# end of script
echo -e "$GREEN ********* end : ezinit.sh *************** $ENDCOLOR"
exit 0;
