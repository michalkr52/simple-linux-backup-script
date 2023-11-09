#!/bin/bash
#
# Author                : Krause Michał 188592
# Created On            : 2022-06-13 23:47:54
# Last Modified By      : Krause Michał 188592
# Last Modified On      : 2023-11-09 13:06:12
# Version               : 1.1
#
# Description
# Script for easy backup creation.
# Options include compression and periodic copies.
#
# File responsible for performing periodic backups from a text file.
# Designed to be called from crontab.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact the Free Software Foundation for a copy)

VERSION="1.1"
WINDOW_TITLE="Backup (crontab)"
READ_FROM_FILE=1
FILE_NAME=""
DIRS=()
QUIT=0


while getopts ":hvf:" opt; do
    case ${opt} in
        h)
            echo "Script for easy backup creation."
            echo "File responsible for performing periodic backups from a previously saved file."
            echo "Options available:"
            echo "-h        display this message"
            echo "-v        display author and script version information"
            echo "-p file   run the script with options saved in the specified file"
            QUIT=1
            ;;
        v)
            echo "Author: Michał Krause 188592"
            echo "Version: $VERSION CRON"
            QUIT=1
            ;;
        f)
            READ_FROM_FILE=0
            FILE_NAME=$OPTARG
            ;;
    esac
done

if [[ $READ_FROM_FILE -eq 0 ]]; then
    SAVE_TYPE=$(sed -n "1p" $FILE_NAME)
    SAVE_DIR=$(sed -n "2p" $FILE_NAME)
    for dir in $(sed 1,2d $FILE_NAME); do
        DIRS+=($dir)
    done
    
    BACKUP_NAME="backup-$(date +%F-%T)"
    case $SAVE_TYPE in 
        1)
            TEMP_DIR=$(mktemp -d -t backup-XXXXXX)
            for dir in ${DIRS[@]}; do
                cp -pa --parents $dir $TEMP_DIR
            done
            mv $TEMP_DIR/* $SAVE_DIR/$BACKUP_NAME
            rm -r $TEMP_DIR
            ;;
            
        2)
            TEMP_DIR=$(mktemp -d -t backup-XXXXXX)
            for dir in ${DIRS[@]}; do
                cp -pa --parents $dir $TEMP_DIR
            done
            tar -czf "$SAVE_DIR/$BACKUP_NAME.tar.gz" -C $TEMP_DIR .
            rm -r $TEMP_DIR
            ;;
    esac
fi

