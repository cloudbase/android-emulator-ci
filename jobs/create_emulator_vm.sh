#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_summary "Spawning emulator vm: $EMU_VM_NAME."
set_job_state_var EMU_VM_ID=$(boot_vm \
        --nic net-name=$VM_NET_NAME \
        --flavor $EMU_VM_FLAVOR \
        --image $EMU_VM_IMAGE \
        --availability-zone $VM_AVAILABILITY_ZONE \
        $EMU_VM_NAME)
set_job_state_var EMU_VM_IP=$(get_vm_ip $EMU_VM_ID)

log_summary "Waiting for emulator vm to be reachable."
exec_with_retry "ps_emu_vm whoami"

log_summary "Cloning CI scripts."
ps_emu_vm "git clone $CI_GIT_REPO $EMU_VM_SCRIPTS_DIR"

log_summary "Validating emulator vm prerequisites."
ps_emu_vm "$EMU_VM_SCRIPTS_DIR\test_host\check_prerequisites.ps1"

log_summary "Transfering the sdk tools archive."
ps_emu_vm "mkdir -force $EMU_VM_PACKAGES_DIR"
ps_emu_vm "Start-BitsTransfer -Source $ANDROID_SDK_URL" \
          "-Destination $EMU_VM_SDK_TOOLS_PATH"

log_summary "Preparing the Android SDK."
ps_emu_vm "$EMU_VM_SCRIPTS_DIR\test_host\install_sdk.ps1" \
          "-androidSdkArchive $EMU_VM_SDK_TOOLS_PATH"

log_summary "Finished preparing emulator vm."
