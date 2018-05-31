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
