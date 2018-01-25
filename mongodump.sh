#!/bin/sh
YEAR="$(date +'%Y')"
MONTH="$(date +'%m')"
DAY="$(date +'%d')"
TIME="$(date +'%T')"
DEST=/root/backups/MongoDB/$YEAR/$MONTH/$DAY/$TIME/
if [ ! -d $DEST ]; then
	mkdir -p $DEST;
fi
mongodump -h localhost -d onkelhenrys -o $DEST
mongodump -h localhost -d borettslaget -o $DEST
