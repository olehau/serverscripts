#!/bin/bash
#Contains all executions for backup jobs

## Log file configuration
LOG_FILE="/root/backup.log"
LOG_RAW_FILE="/root/backup.raw.log"
LOG_ERROR_FILE="/root/backup.error.log"

## Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function LogMsg {
	now="$(date +'%d/%m/%Y %T')"
	IN="$1"
	echo "$now [LOG]: $IN" >> $LOG_FILE;
	echo "$now [LOG]: $IN" >> $LOG_RAW_FILE;
}

function LogOut {
	now="$(date +'%d/%m/%Y %T')"
	PRINT=false
	if [ -n "$1" ]
	then
		IN="$1"
		echo "$now [LOG]: $IN" >> $LOG_FILE;
		echo "$now [LOG]: $IN" >> $LOG_RAW_FILE;
	else
		while read line; do
			read IN
			echo "$now [LOG]: $IN" >> $LOG_RAW_FILE;
			if [ ! -z "$IN" ]; then
				PRINT=true
			fi
		done
	fi
}

function LogError {
	PRINT=false;
	now="$(date +'%d/%m/%Y %T')"
	if [ -n "$1" ]
	then
		IN="$1"
		echo "$now [LOG]: $IN" >> $LOG_ERROR_FILE;
	else
		while read line; do
			read IN
			echo "$now [LOG]: $IN" >> $LOG_ERROR_FILE;
			if [ ! -z "$IN" ]; then
				PRINT=true
			fi
		done
	fi
	if [ "$PRINT" = true ]; then
		printf "$now ${RED}[AN ERROR OCCURED RUNNING THE BACKUP PROCEDURE]${NC}\n" >> $LOG_FILE;
	fi
}

now="$(date +'%d/%m/%Y %T')"
printf "$now [LOG]: ${GREEN}[STARTING BACKUP SEQUENCE]${NC}\n" >> $LOG_FILE;

LogMsg "Syncing email accounts"

{ stdbuf -eL -oL rsync -av --delete /home/mailboxes/maildir/ /root/backups/mail/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Dumping MySQL databases"

{ stdbuf -eL -oL /bin/bash /root/runbackup.sh 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Dumping PGSQL databases"

{ stdbuf -eL -oL /bin/bash /root/autopgsqlbackup.sh 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Dumping MongoDB databases"

{ stdbuf -eL -oL /bin/bash /root/mongodump.sh 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Moving all backups to Backup server"

{ stdbuf -eL -oL rsync -vrlptD --delete /root/backups/ /mnt/backup-server/backups/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Moving all root scripts to Backup server"8

{ stdbuf -eL -oL cp -v /root/automysqlbackup /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/autopgsqlbackup.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/backupjobs.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/courier-dovecot-migrate.pl /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/createcert.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/mongodump.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/movetoftp.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/myserver.conf /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/newalias.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/newemail.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/runbackup.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/showaliases.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/showemails.sh /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -v /root/TODO /mnt/backup-server/server/scripts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

LogMsg "Creating backup of all server configuration files"

{ stdbuf -eL -oL cp -Rv /etc/dovecot/* /mnt/backup-server/server/configs/dovecot/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/mongodb.conf /mnt/backup-server/server/configs/mongodb/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/mongod.conf /mnt/backup-server/server/configs/mongodb/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/nginx/* /mnt/backup-server/server/configs/nginx/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/postfix/* /mnt/backup-server/server/configs/postfix/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/postgresql/* /mnt/backup-server/server/configs/postgresql/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/supervisor/* /mnt/backup-server/server/configs/supervisor/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/fstab /mnt/backup-server/server/configs/fstab/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/backup-credentials.txt /mnt/backup-server/server/configs/fstab/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError
{ stdbuf -eL -oL cp -Rv /etc/letsencrypt/* /mnt/backup-server/server/letsencrypt/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

#LogMsg "Perfoming backup of vhosts files"

#{ stdbuf -eL -oL rsync -vrlptD --delete /var/www/vhosts/ /mnt/backup-server/server/vhosts/ 2>&3 | LogOut ; } 3>&1 1>&2 | LogError

#
now="$(date +'%d/%m/%Y %T')"
printf "$now [LOG]: ${GREEN}[BACKUP SEQUENCE COMPLETED]${NC}\n" >> $LOG_FILE;
