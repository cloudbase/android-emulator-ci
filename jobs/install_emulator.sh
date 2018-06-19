#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

ensure_vars_set EMULATOR_ARCHIVE_URL

log_summary "Transfering the emulator archive."
ps_emu_vm "Invoke-WebRequest -Uri $EMULATOR_ARCHIVE_URL" \
          "-OutFile $EMU_VM_EMULATOR_ARCH_PATH"

log_summary "Installing the emulator."
start_emu_vm_job "install_emulator" \
                 "-androidEmulatorArchive $EMU_VM_EMULATOR_ARCH_PATH"

mark_job_completed "install_emulator"
