#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_summary "Spawning builder vm: $BUILDER_VM_NAME."
set_job_state_var BUILDER_VM_ID=$(boot_vm \
        --nic net-name=$VM_NET_NAME \
        --flavor $BUILDER_VM_FLAVOR \
        --image $BUILDER_VM_IMAGE \
        --availability-zone $VM_AVAILABILITY_ZONE \
        $BUILDER_VM_NAME)
set_job_state_var BUILDER_VM_IP=$(get_vm_ip $BUILDER_VM_ID)

log_summary "Waiting for builder vm to be reachable."
wait_for_listening_port $BUILDER_VM_IP 22

BUILDER_VM_HOME="/home/$BUILDER_VM_USERNAME"
BUILDER_VM_SCRIPTS_DIR="$BUILDER_VM_HOME/android-emulator-ci"

log_summary "Cloning CI scripts."
ssh_builder_vm "git clone $CI_GIT_REPO $BUILDER_VM_SCRIPTS_DIR"

log_summary "Building the emulator."
ssh_builder_vm "$BUILDER_VM_SCRIPTS_DIR/build_host/build_emulator.sh"

log_summary "Build finished. Fetching the emulator files."
mkdir -p $JOB_PACKAGES_DIR

log_summary "Fetching emulator archive."
scp_builder_vm "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_PACKAGES_DIR/$EMULATOR_ARCHIVE_NAME" \
               "$JOB_PACKAGES_DIR/"

log_summary "Fetching unittests archive."
scp_builder_vm "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_PACKAGES_DIR/$UNITTESTS_ARCHIVE_NAME" \
               "$JOB_PACKAGES_DIR/"

log_summary "Pushing emulator files to the log server."
scp_log_srv "$JOB_PACKAGES_DIR/$EMULATOR_ARCHIVE_NAME" \
            "$LOG_SRV:$LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Pushing unit tests to the log server."
scp_log_srv "$JOB_PACKAGES_DIR/$UNITTESTS_ARCHIVE_NAME" \
            "$LOG_SRV:$LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Fetching builder logs."
mkdir -p $LOCAL_BUILDER_LOG_DIR
scp_builder_vm -R "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_LOG_DIR/" \
                  "$LOCAL_BUILDER_LOG_DIR/"

log_summary "Cleaning up builder vm."
nova delete $BUILDER_VM_ID
