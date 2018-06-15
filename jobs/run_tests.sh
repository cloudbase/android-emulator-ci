#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_summary "Transfering the unit tests archive."
ps_emu_vm "Invoke-WebRequest -Uri $UNITTESTS_ARCHIVE_URL" \
          "-OutFile $EMU_VM_UNITTESTS_ARCH_PATH"

log_summary "Running emulator tests."
start_emu_vm_job "run_tests" "$EMU_VM_UNITTESTS_ARCH_PATH" \
                 "--adtEmuEnabledTests \"$ADT_EMU_ENABLED_TESTS\""

mark_job_completed "run_tests"
