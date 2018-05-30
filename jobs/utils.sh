#!/bin/bash

# This script assumes that the common utils
# scripts have already been sourced.

function ssh_builder_vm () {
    local CMD=$1

    ensure_env_vars_set \
        (BUILDER_VM_USERNAME BUILDER_VM_IP VM_SSH_KEY)

    run_ssh_cmd $BUILDER_VM_USERNAME@$BUILDER_VM_IP \
                $VM_SSH_KEY $CMD
}

function set_job_state_var () {
    local var=$1
    local val=$2

    ensure_env_vars_set (JOB_STATE_RC)

    export $var=$val
    echo "$var=$val" >> $JOB_STATE_RC
}

function scp_builder_vm () {
    ensure_env_vars_set (VM_SSH_KEY)

    scp -o "UserKnownHostsFile /dev/null" \
        -o "StrictHostKeyChecking no" \
        -i $VM_SSH_KEY $@
}

function ps_emu_vm () {
    local CMD="$1"

    ensure_env_vars_set \
        (EMU_VM_IP EMU_VM_USERNAME VM_SSL_CERT_PATH VM_SSL_KEY_PATH)

    # TODO: use certificates.
    run_wsman_ps EMU_VM_IP VM_SSL_CERT_PATH VM_SSL_KEY_PATH $CMD
}
