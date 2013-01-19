#!/bin/bash

# INCLUDES
source generic_functions.sh
source ezinit_header.h

# start script
echo -e "$GREEN ********* start : ezinit.sh *************** $ENDCOLOR"

# demande le nom à donner au projet
read -p 'nom du projet? : ' PROJNAME

# demande si il doit créer l'instance EZ dans le repértoire WEB
goornotgo "créer l'instance EZ dans le repértoire WEB ($WEBPATH) ?"
GO=$?
if [ "$GO" == 0 ]; then
    # verifie que le fichier $EZSOURCE existe et teste si est un fichier ou un dossier
    fileordir $EZSOURCE
    TEST=$?
    if [ "$TEST" == 99 ]; then
	{
        echo -e "$RED je n'arrive pas à trouver $EZSOURCE $ENDCOLOR"
		# demande un chemin pour le fichier source EZ
		# si n'existe pas affiche un message d'erreur et quitte le script
		read -p 'chemin et nom d la source EZ : ' EZSOURCE
        fileordir $EZSOURCE
        TEST=$?
        if [ "$TEST" == 99 ]; then
		{
			echo -e "$RED je n'arrive pas à trouver $EZSOURCE"
			echo -e "********* end : ezinit.sh *************** $ENDCOLOR"
            exit 101;
		}
        elif [ "$TEST" != 1 ] && [ "$TEST" != 2 ]; then
            echo -e "$RED la fonction 'fileordir' retourne une valeur inattendu : $TEST"
			echo -e "********* end : ezinit.sh *************** $ENDCOLOR"
            exit 900;
		fi
	}
    elif [ "$TEST" != 1 ] && [ "$TEST" != 2 ]; then
    	echo -e "$RED la fonction 'fileordir' retourne une valeur inattendu : $TEST"
        echo -e "********* end : ezinit.sh *************** $ENDCOLOR"
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
fi

# demande si il faut créer la base de donné pour le projet
goornotgo "créer la base de données pour le projet ? "
GO=$?
if [ "$GO" == 0 ]; then
{
    JUMP=false
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
            JUMP=true
		}
		fi
	}
	fi

    if [ "$JUMP" == false ]; then
    {
        # remplace les occurences '{NAME}' par le nom du projet
        sudo sed -i "s/{NAME}/$PROJNAME/g" temp_ezinitdb.sql
    
        # ouvre le fichier sql crée pour verifier que tout va bien ;)
        sudo vim temp_ezinitdb.sql 
    
        # attend que la verification manuelle soit terminé (fermeture de vim)
        wait
    
        # se connecte à mysql et execute le create database statement
        mysqlexec "f" "temp_ezinitdb.sql"
    }
    fi
}
else
{
	echo -e "$GREEN La base de donné devra être crée manuellement. $ENDCOLOR"
}
fi

# definie le nom du vhost
VHOST="$PROJNAME.local"
    
# demande si il faut créer un vhost
goornotgo "créer le fichier vhost pour le projet ? "
GO=$?
if [ "$GO" == 1 ] || [ "$GO" == 99 ]; then
{
    JUMP=true
	echo -e "$GREEN le fichier vhost devra être crée manuellement $ENDCOLOR"
}
else
{
    JUMP=false
    # se deplace dans le dossier sites-availables
    cd /etc/apache2/sites-available
    
    # copie le fichier $MODELEVH si existe
    # sinon demande le nom du fichier vhost model et son chemin
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
            JUMP=true
    		echo -e "$RED je n'arrive pas à trouver $MODELEVH"
            echo -e "le fichier vhost devra être crée manuellement $ENDCOLOR"
    	}
    	fi
    }
    fi
}
fi

if [ "$JUMP" == false ]; then
{
    # remplace les occurences '{PATH}' par le chemin des projets web
    sudo sed -i "s@{PATH}@$WEBPATH@g" $VHOST
    # remplace les occurences '{NAME}' par le nom du projet
    sudo sed -i "s/{NAME}/$PROJNAME/g" $VHOST
    
    # ouvre le fichier vhost crée pour verifier que tout va bien ;)
    sudo vim $VHOST 
    
    # attend que la verification manuelle du vhost soit terminé (fermeture de vim)
    wait
}
fi

# demande si activer le site
goornotgo "enable site $VHOST ? "
GO=$?
if [ "$GO" == 0 ]; then
{
    # enable le site
    sudo a2ensite $VHOST
    # reload apache config
    sudo /etc/init.d/apache2 reload
}
fi

# demande si ecrire le site dans /etc/hosts
goornotgo "mettre à jour /etc/hosts ? "
GO=$?
if [ "$GO" == 0 ]; then
{
    # met à jour le fichier /etc/hosts
    echo -e "\n$ADRESSEIP    $VHOST\n$ADRESSEIP    admin.$VHOST" | sudo tee -a /etc/hosts
    # ouvre le /etc/hosts pour verification
    sudo vim /etc/hosts
    # attend la verification
    wait
    
    # restart apache
    sudo /etc/init.d/apache2 restart
}
fi

# info
echo -e "$GREEN si vous desirez annuller les operations effectués éxécuter le script ezinit_cleanup.sh"

# end of script
echo -e " ********* end : ezinit.sh *************** $ENDCOLOR"
exit 0;
