#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_summary "Spawning emulator vm: $EMU_VM_NAME."
EMU_VM_ID=$(boot_vm \
            --nic net-name=$VM_NET_NAME \
            --flavor $EMU_VM_FLAVOR \
            --image $EMU_VM_IMAGE \
            --availability-zone $VM_AVAILABILITY_ZONE \
            --user-data $VM_SSL_CERT_PATH \
            --key-name $KEYPAIR_NAME \
            $EMU_VM_NAME)
set_job_state_var EMU_VM_ID $EMU_VM_ID

EMU_VM_IP=$(get_vm_ip $EMU_VM_ID)
set_job_state_var EMU_VM_IP $EMU_VM_IP

log_summary "Waiting for emulator vm to be reachable."
exec_with_retry "ps_emu_vm whoami" \
                $(( EMU_VM_REACHABLE_TIMEOUT / 5 )) 5

log_summary "Cloning CI scripts."
ps_emu_vm "git clone $CI_GIT_REPO $EMU_VM_SCRIPTS_DIR"

log_summary "Validating emulator vm prerequisites."
start_emu_vm_job "check_prerequisites"

log_summary "Transfering the sdk tools archive."
ps_emu_vm "mkdir -force $EMU_VM_PACKAGES_DIR"
ps_emu_vm "Invoke-WebRequest -Uri $ANDROID_SDK_URL" \
          "-OutFile $EMU_VM_SDK_TOOLS_PATH"

log_summary "Preparing the Android SDK."
start_emu_vm_job "install_sdk" \
                 "-androidSdkArchive $EMU_VM_SDK_TOOLS_PATH"

log_summary "Finished preparing emulator vm."

mark_job_completed "create_emulator_vm"
