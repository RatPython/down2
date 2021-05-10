#!/bin/bash

if [ ! -z "$1" ]
then
    TR_TORRENT_DIR="/volume3/down/download"
    TR_TORRENT_HASH=$1
    TR_TORRENT_ID=$2
    TR_TORRENT_NAME=$3
fi

echo "TR_TORRENT_DIR:[$TR_TORRENT_DIR]"
echo "TR_TORRENT_HASH:[$TR_TORRENT_HASH]"
echo "TR_TORRENT_ID:[$TR_TORRENT_ID]"
echo "TR_TORRENT_NAME:[$TR_TORRENT_NAME]"

export TR_TORRENT_DIR
export TR_TORRENT_HASH
export TR_TORRENT_ID
export TR_TORRENT_NAME

cd /opt/down-scripts

#/usr/bin/python3 ./db-insert.py "$TR_TORRENT_HASH" "$TR_TORRENT_ID" "$TR_TORRENT_NAME"

#/usr/bin/perl  ./db-insert.pl "$TR_TORRENT_HASH" "$TR_TORRENT_ID" "$TR_TORRENT_NAME"

echo "$TR_TORRENT_DIR:$TR_TORRENT_HASH:$TR_TORRENT_ID:$TR_TORRENT_NAME" >> /tmp/db-insert.log

/bin/perl  ./send.pl "$TR_TORRENT_DIR" "$TR_TORRENT_HASH" "$TR_TORRENT_ID" "$TR_TORRENT_NAME"


#/usr/bin/perl  ./db-insert.pl "/data/downloads" "HASH" "111" "K-Lite Codec Pack 14.6.0 + Update"
#/usr/bin/perl  ./db-insert.pl "/data/downloads" "$1" "$2" "$3"





