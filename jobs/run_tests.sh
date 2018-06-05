#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

ps_emu_vm "Invoke-WebRequest -Uri $ANDROID_SDK_URL" \
          "-OutFile $EMU_VM_SDK_TOOLS_PATH"

log_summary "Transfering the unit tests archive."
ps_emu_vm "Invoke-WebRequest -Uri $UNITTESTS_ARCHIVE_URL" \
          "-OutFile $EMU_VM_UNITTESTS_ARCH_PATH"

log_summary "Running emulator tests."
start_emu_vm_job "run_tests" "$EMU_VM_UNITTESTS_ARCH_PATH"

mark_job_completed "run_tests"
