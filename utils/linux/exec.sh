#!/bin/bash

basedir_utils=$(dirname "$BASH_SOURCE")

function exec_with_retry2 () {
    local MAX_RETRIES=$1
    local INTERVAL=$2
    local COUNTER=0

    while [ $COUNTER -lt $MAX_RETRIES ]; do
        EXIT=0
        eval '${@:3}' || EXIT=$?
        if [ $EXIT -eq 0 ]; then
            return 0
        fi
        let COUNTER=COUNTER+1

        if [ -n "$INTERVAL" ]; then
            sleep $INTERVAL
        fi
    done
    return $EXIT
}

function exec_with_retry () {
    local CMD=$1
    local MAX_RETRIES=${2-10}
    local INTERVAL=${3-0}

    exec_with_retry2 $MAX_RETRIES $INTERVAL $CMD
}

function run_wsmancmd() {
    local HOST=$1
    local USERNAME=$2
    local CERT_PATH=$3
    local CERT_KEY_PATH=$4
    local CMD=$5

    python "$basedir_utils/wsman.py" \
           -U https://$HOST:5986/wsman \
           -u $USERNAME -k $CERT_PATH -K $CERT_KEY_PATH \
           $CMD
}

function run_wsman_ps() {
    local HOST=$1
    local USERNAME=$2
    local CERT_PATH=$3
    local CERT_KEY_PATH=$4
    local CMD=$5

    CMD="powershell -NonInteractive" \
        "-ExecutionPolicy RemoteSigned" \
        "-Command $CMD"
    run_wsman_cmd $HOST $USERNAME $CERT_PATH $CERT_KEY_PATH $CMD
}

function run_ssh_cmd () {
    local SSHUSER_HOST=$1
    local SSHKEY=$2
    local CMD=$3

    ssh -t -o 'PasswordAuthentication no' \
           -o 'StrictHostKeyChecking no' \
           -o 'UserKnownHostsFile /dev/null' \
           -i $SSHKEY $SSHUSER_HOST "$CMD"
}

function wait_for_listening_port () {
    HOST=$1
    PORT=$2
    exec_with_retry 15 10 "nc -z -w15 $HOST $PORT"
}
