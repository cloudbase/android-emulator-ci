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

    required_vars=(EMU_VM_IP EMU_VM_USERNAME VM_SSL_CERT_PATH VM_SSL_KEY_PATH)
    ensure_env_vars_set $required_vars

    run_wsman_ps $EMU_VM_IP $EMU_VM_USERNAME \
                 $VM_SSL_CERT_PATH $VM_SSL_KEY_PATH "$CMD"
}

function start_emu_vm_job () {
    local JOB_NAME=$1
    local JOB_ARGS="${@:2}"
    local JOB_LOG_FILE="$EMU_VM_LOG_DIR\\$JOB_NAME.log"

    ps_emu_vm "mkdir -Force $EMU_VM_LOG_DIR"

    CMD="$EMU_VM_SCRIPTS_DIR\\test_host\\$JOB_NAME.ps1 $JOB_ARGS"
    CMD="$CMD > $JOB_LOG_FILE 2>&1"

    ps_emu_vm "$CMD"
}

function mark_job_completed () {
    local JOB_NAME=$1
    local JOB_RET_VAL=${2:0}
    local JOB_FILE="$FINISHED_JOBS_DIR/$JOB_NAME"

    log_summary "Marking job $JOB_NAME as completed." \
                "Return value: $JOB_RET_VAL"
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
