#!/bin/bash

# This script assumes that the common utils
# scripts have already been sourced.

function ssh_builder_vm () {
    local CMD="$@"

    required_vars=(BUILDER_VM_USERNAME BUILDER_VM_IP VM_SSH_KEY)
    ensure_env_vars_set $required_vars

    run_ssh_cmd $BUILDER_VM_USERNAME@$BUILDER_VM_IP \
                $VM_SSH_KEY "$CMD"
}

function set_job_state_var () {
    local var=$1
    local val=$2

    required_vars=(JOB_STATE_RC var val)
    ensure_env_vars_set $required_vars

    export $var=$val
    echo "$var=$val" >> $JOB_STATE_RC
}

function scp_builder_vm () {
    ensure_env_vars_set VM_SSH_KEY

    scp -o "UserKnownHostsFile /dev/null" \
        -o "StrictHostKeyChecking no" \
        -i $VM_SSH_KEY $@
}

function scp_log_srv () {
    ensure_env_vars_set LOG_SRV_KEY

    scp -o "UserKnownHostsFile /dev/null" \
        -o "StrictHostKeyChecking no" \
        -i $LOG_SRV_KEY $@
}

function ssh_log_srv () {
    local CMD="$@"

    required_vars=(LOG_SRV LOG_SRV_USERNAME LOG_SRV_KEY)
    ensure_env_vars_set $required_vars

    run_ssh_cmd $LOG_SRV_USERNAME@$LOG_SRV \
                $LOG_SRV_KEY "$CMD"
}

function ps_emu_vm () {
    local CMD="$@"

    required_vars=(EMU_VM_IP EMU_VM_USERNAME \
                   VM_SSL_CERT_PATH VM_SSL_KEY_PATH)
    ensure_env_vars_set $required_vars

    run_wsman_ps $EMU_VM_IP $EMU_VM_USERNAME \
                 $VM_SSL_CERT_PATH $VM_SSL_KEY_PATH "$CMD"
}

function start_emu_vm_job () {
    local JOB_NAME=$1
    local JOB_ARGS="${@:2}"
    local JOB_LOG_FILE="$EMU_VM_LOG_DIR\\$JOB_NAME.log"

    ps_emu_vm "mkdir -Force $EMU_VM_LOG_DIR"

    local CMD="$EMU_VM_SCRIPTS_DIR\\test_host\\$JOB_NAME.ps1 $JOB_ARGS"
    CMD="$CMD > $JOB_LOG_FILE 2>&1"

    ps_emu_vm "$CMD"
}

function call_emu_vm_script () {
    local SCRIPT_NAME="$(echo $1 | sed 's/\.ps1$//')"
    local SCRIPT_ARGS="${@:2}"
    local CMD="$EMU_VM_SCRIPTS_DIR\\test_host\\$SCRIPT_NAME.ps1 $SCRIPT_ARGS"

    ps_emu_vm "$CMD"
}

function mark_job_completed () {
    local JOB_NAME=$1
    local JOB_RET_VAL=${2:-0}
    local JOB_FILE="$FINISHED_JOBS_DIR/$JOB_NAME"

    log_summary "Job \"$JOB_NAME\" completed." \
                "Return value: \"$JOB_RET_VAL\""
    mkdir -p $FINISHED_JOBS_DIR
    echo $JOB_RET_VAL > $JOB_FILE
}

function get_job_ret_val () {
    local JOB_NAME=$1
    local JOB_FILE="$FINISHED_JOBS_DIR/$JOB_NAME"

    if [[ ! -f $JOB_FILE ]]; then
        return -1
    fi
    cat $JOB_FILE
}

function check_job_completed () {
    local JOB_NAME=$1
    local JOB_FILE="$FINISHED_JOBS_DIR/$JOB_NAME"

    if [[ ! -f $JOB_FILE ]]; then
        return -1
    fi
    return 0
}

function mount_emu_vm_share () {
    local SHARE_NAME=$1
    local MOUNT_PATH=$2

    required_vars=(EMU_VM_ID EMU_VM_IP VM_SSH_KEY \
                   SHARE_NAME MOUNT_PATH)
    ensure_env_vars_set $required_vars

    local EMU_VM_PASSWORD
    EMU_VM_PASSWORD=$(nova get-password $EMU_VM_ID $VM_SSH_KEY)

    local SHARE_PATH="//$EMU_VM_IP/$SHARE_NAME"
    log_summary "Mounting $SHARE_PATH to $MOUNT_PATH."

    mkdir -p $MOUNT_PATH

    if [[ $(is_wsl) ]]; then
        # WSL doesn't allow mounting SMB shares directly.
        local SHARE_UNC_PATH
        SHARE_UNC_PATH=$(cifs_to_unc_path $SHARE_PATH)
        net.exe use $SHARE_UNC_PATH \
                    /user:$EMU_VM_USERNAME $EMU_VM_PASSWORD
        sudo mount -t drvfs $SHARE_UNC_PATH $MOUNT_PATH
    else
        sudo mount -t cifs -o \
            username="$EMU_VM_USERNAME",password="$EMU_VM_PASSWORD" \
            $SHARE_PATH $MOUNT_PATH \
            -o vers=3.0
    fi
}

function cleanup_vm () {
    if str_to_bool $SKIP_VM_CLEANUP; then
        log_summary "Skipping vm cleanup: $1"
    else
        delete_vm_if_exists $@
    fi
}
