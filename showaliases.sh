#!/bin/bash

psql -U mailreader -d mail -c "SELECT * FROM aliases"
