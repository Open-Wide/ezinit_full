#!/bin/bash

# INIT VARIABLES
MODELESDIR="/data/repositories/git/ezinit_full/ezinit_full_modeles/"
MODELEVH=$MODELESDIR"ez_generic_vhost" #generic vhost
MODELEMYSQL=$MODELESDIR"ez_generic_initdb.sql" # generic database create mysql
EZSOURCE="/data/home/mpasquesi/DEV/sources/EZ/ezpublish-enterprise-4.5.0-pul.zip" #instance ezpublish vierge
WORKPATH="/data/home/mpasquesi/DEV/"
WEBPATH="/data/services/web/" #chemin des projets web
ADRESSEIP="127.0.0.1" # adresse IP pour le site (normalement 127.0.0.1)
MYSQLUSR="root" # connexion à mysql : user et pswd
MYSQLPSWD=""
