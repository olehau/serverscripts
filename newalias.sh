#!/bin/bash

echo Please enter the email account

read email

echo Please enter the alias

read alias

psql -U mailreader -d mail -c "INSERT INTO aliases (alias, email) VALUES ('$alias', '$email')"
