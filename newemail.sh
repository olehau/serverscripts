#!/bin/bash

echo Please enter the email address

read email

echo Please enter directory name

read DIR

echo Please enter password

read -s password

echo Retype the password

read -s password2

HASHEDPASS=$(doveadm pw -s sha512 -r 100 -p $password)

psql -U mailreader -d mail -c "INSERT INTO users (email, password, maildir) VALUES ('$email', '$HASHEDPASS', '$DIR')"
