#!/bin/bash

# INCLUDES
source generic_functions.sh
source ezinit_header.h

# start script
echo -e "$GREEN ********* start : ezinit_cleanup.sh *************** $ENDCOLOR"

# demande le nom du projet à supprimer
read -p 'nom du projet à supprimer? : ' PROJNAME

# se deplace dans le dossier $WEBPATH
cd $WEBPATH

# demande si il faut supprimer l'instance EZ dans le repertoire des sites web
goornotgo "est que il faut supprimer l'instance web ? "
GO=$?
if [ "$GO" == 0 ]; then
{
    # supprime l'instance EZ dans le repertoire des sites web
    sudo rm -rf $PROJNAME
    ls -la $WEBPATH
}
fi

# liste les fichiers dans $WEBPATH pour verification
ls -la $WEBPATH

# demande si il y a un lien symbolic dans /var/www/ à supprimer
goornotgo "est que il faut supprimer un lien symbolic dans /var/www/ ?"
GO=$?
if [ "$GO" == 0 ]; then
	sudo rm -rv /var/www/$PROJNAME
	ls -la /var/www/
fi

# demande si il y a une base de donné à supprimer
goornotgo "est que il y a une base de données à supprimer ? "
GO=$?
if [ "$GO" == 0 ]; then
{
	mysqlexec "e" "drop database $PROJNAME;"
    mysqlexec "e" "show databases;"
}
fi

# demande si il y a un vhost dans à supprimer
goornotgo "est que il faut supprimer un vhost ?"
GO=$?
if [ "$GO" == 0 ]; then
	# se deplace dans le dossier sites-availables
	cd /etc/apache2/sites-available
	sudo a2dissite $PROJNAME.local
	sudo /etc/init.d/apache2 reload
	sudo rm -f $PROJNAME.local
    ls -la /tc/apache2/sites-available
fi

# demande si il faut supprimer les sites dans /etc/hosts
goornotgo "est que il faut supprimer les sites dans /etc/hosts ?"
GO=$?
if [ "$GO" == 0 ]; then
	# met à jour le fichier /etc/hosts
	sudo sed -i "s/$ADRESSEIP    $PROJNAME.local//g" /etc/hosts
	sudo sed -i "s/$ADRESSEIP    admin.$PROJNAME.local//g" /etc/hosts
	# ouvre le /etc/hosts pour verification
	sudo vim /etc/hosts
	# attend la verification
	wait
	# restart apache
	sudo /etc/init.d/apache2 restart
fi


# end of script
echo -e "$GREEN ********* end : ezinit_cleanup.sh *************** $ENDCOLOR"
exit 0;
