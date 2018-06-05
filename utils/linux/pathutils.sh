#!/bin/bash

function ensure_dir_empty () {
    local DIR=$1

    log_summary "Cleanning up dir: $1"
    rm -rf $DIR
    mkdir -p $DIR
}

function cifs_to_unc_path () {
    echo $1 | tr / "\\" 2> /dev/null
}

function ensure_unmounted () {
    local MOUNT=$1
    local FORCE=$2

    local MOUNTED=$(mount | awk '{print $3}' | grep -w $MOUNT)
    if [[ -z $MOUNTED ]]; then
        log_summary "\"$MOUNT\" is not mounted. Skipping unmount."
    else
        log_summary "Unmounting \"$MOUNT\"."
        if [ -z $FORCE ]; then
            umount $MOUNT
        else
            sudo umount -f $MOUNT
        fi
    fi
}
