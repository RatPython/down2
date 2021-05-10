#!/bin/bash
cd /opt/down-scripts

echo "$1 $2 $3" >> /tmp/bbdi

/usr/bin/perl ./send.pl "$1" "$2" "$3" >>/tmp/bstd 2>&1
