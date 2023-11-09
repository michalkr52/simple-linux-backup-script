#!/bin/bash
#
# Author                : Krause Michał 188592
# Created On            : 2022-06-13 11:24:12
# Last Modified By      : Krause Michał 188592
# Last Modified On      : 2023-11-09 13:00:31
# Version               : 1.1
#
# Description
# Script enabling easy backup of selected directories.
# Options include compression and periodic backups.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact the Free Software Foundation for a copy)

VERSION="1.1"
WINDOW_TITLE="Backup Creator"
DEFAULT_DIRS_PATH=("$HOME" "/home" "/etc" "/bin" "/usr" "/usr/local" "/usr/bin" "/var")
DEFAULT_DIRS_DESC=("($(whoami))'s home directory" "Users' home directories" "Configuration files" \
                    "Essential binaries" "User binariese" "Locally installed binaries" "User system binaries" "Variable data")
READ_FROM_FILE=1
FILE_NAME=""
DIRS=()
QUIT=0


while getopts ":hvf:" opt; do
    case ${opt} in
        h)
            echo "Script for easy backup creation."
            echo "Available options:"
            echo "-h        display this message"
            echo "-v        display author and script version information"
            echo "-f file   run the script with options saved in the specified file"
            QUIT=1
            ;;
        v)
            echo "Author: Michał Krause 188592"
            echo "Version: $VERSION"
            QUIT=1
            ;;
        f)
            READ_FROM_FILE=0
            FILE_NAME=$OPTARG
            ;;
    esac
done

while [[ $QUIT -eq 0 ]]; do
    if [[ $READ_FROM_FILE -ne 0 ]]; then
        zenity --question --title="$WINDOW_TITLE" --icon-name=info --width=200 --height=100 \
                --text="<span size='x-large'>Welcome to the Backup Creator</span>\n\nDo you want to load options from file?" \
                --ok-label="Load options from file" --cancel-label="Proceed"
        READ_FROM_FILE=$?
        if [[ $READ_FROM_FILE -eq 0 ]]; then
            FILE_NAME=$(zenity --entry --title="$WINDOW_TITLE: Load options" --text="Enter the absolute path of the file:")
            if [[ -z $FILE_NAME ]]; then
                zenity --error --title="$WINDOW_TITLE: Error" --text="No file provided" --width=150
                READ_FROM_FILE=1
            fi
        fi
    fi
    
    if [[ $READ_FROM_FILE -eq 0 ]]; then
        FILE_NAME="${FILE_NAME/#\~/$HOME}"
        zenity --question --title="$WINDOW_TITLE: Load options" --text="Are you sure you want to load options from $FILE_NAME?" \
                --cancel-label="No" --ok-label="Yes" --width=150
        READ_CONFIRM=$?
        if [[ READ_CONFIRM -eq 0 ]]; then
            if [[ -e $FILE_NAME ]]; then
                for dir in $(cat $FILE_NAME); do
                    DIRS+=($dir)
                done
            else
                zenity --error --title="$WINDOW_TITLE: Error" --text="Unable to open file" --width=200
            fi
        fi
    fi
    
    READY=0
    while [[ $READY -eq 0 ]]; do
        RESULT=$(zenity --list --radiolist --title="$WINDOW_TITLE: Select action" --width=400 --height=250 --cancel-label="Exit" \
                        --ok-label="Next" --text="Choose the next action:" --column="Selection" --column="ID" --column="Action" \
                        FALSE 1 "Select from the default list" FALSE 2 "Enter full path" \
                        FALSE 3 "Select using file dialog" FALSE 4 "Show selected items" FALSE 5 "Confirm selection")
        ABORT=$?
        if [[ $ABORT -eq 1 ]]; then
            zenity --question --title="$WINDOW_TITLE: Exit" --text="Are you sure you want to exit the creator?" \
                    --cancel-label="No" --ok-label="Yes" --width=150
            ABORT_CONFIRM=$?
            if [[ ABORT_CONFIRM -eq 0 ]]; then
                QUIT=1
                READY=1
            fi   
             
        else
            case $RESULT in 
            1)
                ROWS=()
                for i in "${!DEFAULT_DIRS_PATH[@]}"; do
                    DIR_FOUND=0
                    for dir in "${DIRS[@]}"; do
                        if [[ "${DEFAULT_DIRS_PATH[$i]}" == "$dir" ]]; then
                            DIR_FOUND=1
                        fi
                    done
                    if [[ $DIR_FOUND -eq 0 ]]; then
                        ROWS+=(FALSE "${DEFAULT_DIRS_PATH[$i]}" "${DEFAULT_DIRS_DESC[$i]}")
                    else
                        ROWS+=(TRUE "${DEFAULT_DIRS_PATH[$i]}" "${DEFAULT_DIRS_DESC[$i]}")
                    fi
                done
                
                RESULT=$(zenity --list --checklist --title="$WINDOW_TITLE: Item selection" --width=500 --height=300 \
                                --cancel-label="Back" --ok-label="Add" --text="Choose items:" \
                                --column="Selection" --column="Path" --column="Description" "${ROWS[@]}")
                RESULT_ARRAY=(${RESULT//|/ })
                for result in "${RESULT_ARRAY[@]}"; do
                    DIR_FOUND=0
                    for dir in "${DIRS[@]}"; do
                        if [[ "$result" == "$dir" ]]; then
                            DIR_FOUND=1
                        fi
                    done
                    if [[ $DIR_FOUND -eq 0 ]]; then
                        DIRS+=("$result")
                    fi
                done
                ;;
                
            2)
                RESULT=$(zenity --entry --title="$WINDOW_TITLE: Item selection" --text="Enter the absolute path of the item:")
                if [[ -n $RESULT ]]; then
                    RESULT="${RESULT/#\~/$HOME}"
                    DIR_FOUND=0
                    for dir in "${DIRS[@]}"; do
                        if [[ "$RESULT" == "$dir" ]]; then
                            DIR_FOUND=1
                        fi
                    done
                    if [[ $DIR_FOUND -eq 0 ]]; then
                        if [[ -r $RESULT ]]; then
                            DIRS+=("$RESULT")
                        else
                            zenity --error --title="$WINDOW_TITLE: Item selection" --width=200 \
                                    --text="Cannot read item at path $RESULT"
                        fi
                    fi
                fi
                ;;
                
            3)
                RESULT=$(zenity --file-selection --directory --multiple --title="$WINDOW_TITLE: Item selection")
                RESULT_ARRAY=(${RESULT//|/ })
                for result in "${RESULT_ARRAY[@]}"; do
                    DIR_FOUND=0
                    for dir in "${DIRS[@]}"; do
                        if [[ "$result" == "$dir" ]]; then
                            DIR_FOUND=1
                        fi
                    done
                    if [[ $DIR_FOUND -eq 0 ]]; then
                        DIRS+=("$result")
                    fi
                done
                ;;
                
            4)
                zenity --list --title="$WINDOW_TITLE: Selected items" --text="Selected items:" \
                        --cancel-label="Return" --width=300 --height=400 --column="Path" "${DIRS[@]}"
                ;;
                
            5)
                READY=1
                ;;
            esac
            
            if [[ $READY -eq 1 ]]; then
                SAVE_RESULT=$(zenity --list --radiolist --title="$WINDOW_TITLE" --width=300 --height=150 --cancel-label="Return" \
                        --ok-label="Choose destination path" --text="Choose backup type:" --column="Selection" --column="ID" \
                        --column="Type" FALSE 1 "Directory" FALSE 2 "Archive")
                ACTION=$?
                if [[ $ACTION -eq 1 ]]; then
                    READY=0
                else
                    SAVE_DIR=$(zenity --file-selection --directory --title="$WINDOW_TITLE: Choose destination path")
                    if [[ -z $SAVE_DIR ]]; then
                        READY=0
                    else
                        BACKUP_NAME="backup-$(date +%F-%T)"
                        case $SAVE_RESULT in 
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
                        
                        zenity --question --title="$WINDOW_TITLE" --text="Would you like to execute the backup regularly?" \
                            --cancel-label="No" --ok-label="Yes" --width=150
                        CRON_RESULT=$?
                        if [[ $CRON_RESULT -eq 0 ]]; then
                            CRON_OPTIONS=$(zenity --forms --title="$WINDOW_TITLE: Add to crontab" \
                            --text="Enter parameters for crontab entry:\n(use '*' for 'any' value)" \
                            --add-entry="Minute [0-59]:" --add-entry="Hour [0-23]:" --add-entry="Day of Month [1-31]:" \
                            --add-entry="Month [1-12]:" --add-entry="Day of Week [0-6]:" --separator=" ")
                            if [[ $? -eq 0 ]]; then
                                TEMP_CRONTAB=$(mktemp -t backup-cron-XXXXXX)
                                crontab -l > $TEMP_CRONTAB
                                echo "$CRON_OPTIONS $(pwd)/backup_cron.sh -p $SAVE_DIR/$BACKUP_NAME-cron.txt" >> $TEMP_CRONTAB
                                crontab $TEMP_CRONTAB
                                rm $TEMP_CRONTAB
                                echo "$SAVE_RESULT" >> "$SAVE_DIR/$BACKUP_NAME-cron.txt"
                                echo "$SAVE_DIR" >> "$SAVE_DIR/$BACKUP_NAME-cron.txt"
                                for dir in ${DIRS[@]}; do
                                    echo $dir >> "$SAVE_DIR/$BACKUP_NAME-cron.txt"
                                done
                            else
                                CRON_RESULT=1
                            fi
                        fi
                        
                        zenity --question --title="$WINDOW_TITLE" --text="Would you like to save the settings to a file?" \
                            --cancel-label="No" --ok-label="Yes" --width=200
                        if [[ $? -eq 0 ]]; then
                            for dir in ${DIRS[@]}; do
                                echo $dir >> "$SAVE_DIR/$BACKUP_NAME.txt"
                            done
                        fi
                    fi
                fi
            fi
            
            if [[ $READY -eq 1 ]]; then
                QUIT=1
            fi
        fi
    done
done

