#!/bin/bash

# INIT VARIABLES
MODELEVH='/data/home/mpasquesi/DEV/conf/ez_generic_vhost' #generic vhost
WEBPATH='/data/services/web/' #chemin des projets web
EZSOURCE='/data/home/mpasquesi/DEV/sources/EZ/ezpublish-4.5.0-with_ezc-ee-pul' #instance ezpublish vierge
ADRESSEIP="127.0.0.1" # adresse IP pour le site (normalement 127.0.0.1)
MYSQLCONNECT="-u root" # connexion à mysql : user et pswd
MODELEMYSQL="/data/home/mpasquesi/DEV/conf/ez_generic_initdb.sql" # generic database create mysql
WORKPATH="/data/home/mpasquesi/DEV/"
