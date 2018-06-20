#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

if str_to_bool $SKIP_BUILD; then
    log_summary "Skipped building the emulator."
    mark_job_completed "build_emulator"
    exit 0
fi

log_summary "Spawning builder vm: $BUILDER_VM_NAME."

BUILDER_VM_ID=$(boot_vm \
                --nic net-name=$VM_NET_NAME \
                --flavor $BUILDER_VM_FLAVOR \
                --image $BUILDER_VM_IMAGE \
                --availability-zone $VM_AVAILABILITY_ZONE \
                --key-name $KEYPAIR_NAME \
                $BUILDER_VM_NAME)
set_job_state_var BUILDER_VM_ID $BUILDER_VM_ID
wait_for_instance_boot $BUILDER_VM_ID $VM_BOOT_TIMEOUT

BUILDER_VM_IP=$(get_vm_ip $BUILDER_VM_ID)
set_job_state_var BUILDER_VM_IP $BUILDER_VM_IP

log_summary "Waiting for builder vm to be reachable."
wait_for_listening_port $BUILDER_VM_IP 22

BUILDER_VM_HOME="/home/$BUILDER_VM_USERNAME"
BUILDER_VM_SCRIPTS_DIR="$BUILDER_VM_HOME/android-emulator-ci"

log_summary "Cloning CI scripts."
ssh_builder_vm "rm -rf $BUILDER_VM_SCRIPTS_DIR"
ssh_builder_vm "git clone -q $CI_GIT_REPO $BUILDER_VM_SCRIPTS_DIR"

emulator_build_failed=""
log_summary "Building the emulator."
ssh_builder_vm "SKIP_DEPS=$BUILDER_IMAGE_CACHE" \
               "GERRIT_CHANGE_NUMBER=$GERRIT_CHANGE_NUMBER" \
               "GERRIT_PATCHSET_NUMBER=$GERRIT_PATCHSET_NUMBER" \
               "$BUILDER_VM_SCRIPTS_DIR/build_host/build_emulator.sh" \
               || emulator_build_failed="1"

log_summary "Fetching builder logs."
scp_builder_vm -r "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_LOG_DIR" \
                  "$LOCAL_BUILDER_LOG_DIR"

[[ $emulator_build_failed ]] && die "Failed to build the emulator."

log_summary "Fetching the emulator files."
mkdir -p $JOB_PACKAGES_DIR

log_summary "Fetching emulator archive."
scp_builder_vm "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_PACKAGES_DIR/$EMULATOR_ARCHIVE_NAME" \
               "$JOB_PACKAGES_DIR/"

log_summary "Fetching unittests archive."
scp_builder_vm "$BUILDER_VM_USERNAME@$BUILDER_VM_IP:$BUILDER_PACKAGES_DIR/$UNITTESTS_ARCHIVE_NAME" \
               "$JOB_PACKAGES_DIR/"

log_summary "Preparing log server packages dir."
ssh_log_srv "mkdir -p $LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Pushing emulator files to the log server."
scp_log_srv "$JOB_PACKAGES_DIR/$EMULATOR_ARCHIVE_NAME" \
            "$LOG_SRV_USERNAME@$LOG_SRV:$LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Pushing unit tests to the log server."
scp_log_srv "$JOB_PACKAGES_DIR/$UNITTESTS_ARCHIVE_NAME" \
            "$LOG_SRV_USERNAME@$LOG_SRV:$LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Cleaning up builder vm."
cleanup_vm $BUILDER_VM_ID

mark_job_completed "build_emulator"
