#!/bin/bash
#This script is to rescue the server from a complete failure. Installing all dependencies, and copying back the structure and files from backup server. Only to be used upon armageddon. Configured to be run on Debian Stretch.

echo "Type run to execute the resque:"

read run

if [ $run != "run" ]; then
	echo "Exiting execution"
	exit 0;
fi

echo "Commencing resque operation"

#Make sure APT is up to date
sudo apt-get update

# Install cifs utils to mount backup disk
sudo apt-get install cifs-utils -y

#Install nginx
sudo apt-get install -y nginx

#Install MySQL / MariaDB
sudo apt-get install mysql-server -y

sudo mysql_secure_installation

# Install PHP5
sudo apt-get update && apt-get install -y apt-transport-https lsb-release ca-certificates wget
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
sudo apt-get update && apt-get install -y php5.6-fpm php5.6-mysql
sudo apt-get install php5.6-dev php5.6-cli php-pear php5.6-xml php-xml -y

## Install mongo dependencies
sudo apt-get install libssl-dev -y
sudo apt-get install libcurl4-openssl-dev -y
sudo apt-get install pkg-config libssl-dev -y

## Install mongo
sudo pecl install mongo

# Install MongoDB
sudo apt-get install dirmngr -y
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
wget http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u7_amd64.deb && dpkg -i libssl1.0.0_1.0.1t-1+deb8u7_amd64.deb
sudo apt-get update && apt-get install -y mongodb-org

# Install PostgreSQL
sudo apt-get install postgresql postgresql-client -y

# Install Dovecot & Postfix
sudo apt-get remove exim4 -y && apt-get install postfix -y && postfix stop
sudo apt-get install dovecot-core dovecot-imapd -y
sudo apt-get install dovecot-common -y

# Install Supervisor
sudo apt-get install supervisor -y

# Install letsencrypt
sudo apt-get install python-certbot-nginx -t stretch-backports -y
sudo certbot --authenticator standalone --installer nginx --pre-hook "nginx -s stop" --post-hook "nginx"

# Install Node
sudo apt-get install curl -y
curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install nodejs -y
sudo apt-get install build-essential -y

# Install Composer
sudo apt-get install curl php5.6-cli git -y
sudo php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
sudo php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === 'sha_384_string') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
sudo rm /tmp/composer-setup.php

# Mount the Backup Disk
sudo touch /etc/backup-credentials.txt
echo "username=********" >> /etc/backup-credentials.txt
echo "password=*********" >> /etc/backup-credentials.txt
echo "//********.your-backup.de/backup /mnt/backup-server cifs iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,file_mode=0660,dir_mode=0770 0 0" | sudo tee /etc/fstab
mount -a

# Transfer configuration files from backup
cp -R /mnt/backup-server/server/configs/nginx/ /etc/nginx/
cp -R /mnt/backup-server/server/configs/mongodb/mongodb.conf /etc/mongodb.conf
cp -R /mnt/backup-server/server/configs/mongodb/mongod.conf /etc/mongod.conf
cp -R /mnt/backup-server/server/configs/dovecot/ /etc/dovecot/
cp -R /mnt/backup-server/server/configs/postfix/ /etc/postfix/
cp -R /mnt/backup-server/server/configs/supervisor/ /etc/supervisor/
cp -R /mnt/backup-server/server/configs/php/ /etc/php/
cp -R /mnt/backup-server/server/configs/postgresql/ /etc/postgresql/

# Transfer letsencrypt certs
cp -R /mnt/backup-server/server/letsencrypt/ /etc/letsencrypt/

# Transfer mailaccount
mkdir /home/mailboxes/maildir
cp -R /mnt/backup-server/backups/mail/* /home/mailboxes/maildir/

# Transfer the root scripts
cp /mnt/backup-server/server/scripts/automysqlbackup /root/ && chmod +x /root/automysqlbackup
cp /mnt/backup-server/server/scripts/autopgsqlbackup.sh /root/ && chmod +x /root/autopgsqlbackup.sh
cp /mnt/backup-server/server/scripts/backupjobs.sh /root/ && chmod +x /root/backupjobs.sh
cp /mnt/backup-server/server/scripts/courier-dovecot-migrate.pl /root/ && chmod +x /root/courier-dovecot-migrate.pl && /bin/bash /root/courier-dovecot-migrate.pl --to-dovecot --recursive /home/mailboxes/maildir && chown -R vmail:vmail /home/mailboxes/maildir/
cp /mnt/backup-server/server/scripts/createcert.sh /root/ && chmod +x /root/createcert.sh
cp /mnt/backup-server/server/scripts/mongodump.sh /root/ && chmod +x /root/mongodump.sh
cp /mnt/backup-server/server/scripts/movetoftp.sh /root/ && chmod +x /root/movetoftp.sh
cp /mnt/backup-server/server/scripts/myserver.conf /root/
cp /mnt/backup-server/server/scripts/newalias.sh /root/ && chmod +x /root/ewalias.sh
cp /mnt/backup-server/server/scripts/newemail.sh /root/ && chmod +x /root/newemail.sh
cp /mnt/backup-server/server/scripts/runbackup.sh /root/ && chmod +x /root/runbackup.sh
cp /mnt/backup-server/server/scripts/showaliases.sh /root/ && chmod +x /root/showaliases.sh
cp /mnt/backup-server/server/scripts/showemails.sh /root/ && chmod +x /root/showemails.sh
cp /mnt/backup-server/server/scripts/TODO /root/

# Transfer vhosts from backup
cp -R /mnt/backup-server/server/vhosts/ /var/www/vhosts/ && chown -R www-data:www-data /var/www/vhosts/

# Start or reload processes
/etc/init.d/nginx restart >> /dev/null 2>&1
/etc/init.d/php5-fpm restart >> /dev/null 2>&1
/etc/init.d/php7.0-fpm restart >> /dev/null 2>&1
/etc/init.d/php7.1-fpm restart >> /dev/null 2>&1
/etc/init.d/php7.2-fpm restart >> /dev/null 2>&1
/etc/init.d/dovecot restart >> /dev/null 2>&1
/etc/init.d/postfix restart >> /dev/null 2>&1
/etc/init.d/mysql restart >> /dev/null 2>&1
/etc/init.d/mongodb restart >> /dev/null 2>&1
/etc/init.d/postgresql restart >> /dev/null 2>&1
/etc/init.d/supervisor restart >> /dev/null 2>&1
