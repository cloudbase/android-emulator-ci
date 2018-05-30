basedir_utils=$(dirname "$0")
source "$basedir_utils/exec.sh"

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
    local PASSWORD=$3
    local CMD=$4

    python "$basedir_utils/wsman.py" -U https://$HOST:5986/wsman -u $USERNAME -p $PASSWORD $CMD
}

function run_wsmancmd_with_retry () {
    local HOST=$1
    local USERNAME=$2
    local PASSWORD=$3
    local CMD=$4

    exec_with_retry "run_wsmancmd $HOST $USERNAME $PASSWORD $CMD"
}

function run_wsman_ps() {
    local HOST=$1
    local USERNAME=$2
    local PASSWORD=$3
    local CMD=$4

    run_wsman_cmd $HOST $USERNAME $PASSWORD "powershell -NonInteractive -ExecutionPolicy RemoteSigned -Command $CMD"
}

function run_ssh_cmd () {
    local SSHUSER_HOST=$1
    local SSHKEY=$2
    local CMD=$3

    ssh -t -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i $SSHKEY $SSHUSER_HOST "$CMD"
}
