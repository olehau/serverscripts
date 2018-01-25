# serverscripts
Scripts that help me with the dailys on a debian server with nginx, php-fpm, dovecot, postfix, postgresql, mariadb and mongodb

## newvhost.sh
This script is configured to easily set up new nginx vhosts on the fly. It supports setting up with both http and https (requires certbot). When configuring with https, new certificates will be generated automagically by certbot and applied to the vhosts configuration file. You will also be given the choice to spin up a new php pool for your new vhost

## newemail.sh
Adds new email account to postgresql-database

## newalias.sh
Adds new email aliases to the postgresql-database

## showemails.sh
Lists all registered email accounts

## showaliases.sh
Lists all registered aliases

## mongodump.sh
Used to dump mongodb-databases to a date specified folder structure

## resque.sh
Used upon dooms day. This will install all my dependencies from a clean Debian Stretch environment, mount my backup hard drive and transfer all configuration files. 

## backupjobs.sh
Used to back up MariaDB, MongoDB, PGSQL, Email accounts, server configuration files and statics to a backup disk. 
