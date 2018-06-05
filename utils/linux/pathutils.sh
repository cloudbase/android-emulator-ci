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

function ensure_share_unmounted () {
    local MOUNT=$1

    MOUNT=$(echo $MOUNT | tr "\\" "/")
    local MOUNTED_SHARE=$(mount | tr "\\" "/" | \
                          grep -E "(^| )$MOUNT " | awk '{print $1}')

    if [[ -z $MOUNTED_SHARE ]]; then
        log_summary "\"$MOUNT\" is not mounted. Skipping unmount."
    else
        log_summary "Unmounting \"$MOUNT\"."
        sudo umount -f $MOUNT

        if [[ $(is_wsl) ]]; then
            net.exe use $(cifs_to_unc_path $MOUNT) /delete
        fi
    fi
}
