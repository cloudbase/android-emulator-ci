#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

if str_to_bool $SKIP_TESTS; then
    log_summary "Skipped running the tests."
    mark_job_completed "run_tests"
    exit 0
fi

ensure_vars_set UNITTESTS_ARCHIVE_URL

log_summary "Transfering the unit tests archive."
ps_emu_vm "Invoke-WebRequest -Uri $UNITTESTS_ARCHIVE_URL" \
          "-OutFile $EMU_VM_UNITTESTS_ARCH_PATH"

log_summary "Running emulator tests."
start_emu_vm_job "run_tests" "$EMU_VM_UNITTESTS_ARCH_PATH" \
                 "-enabledFunctionalTests \"$ENABLED_FUNCTIONAL_TESTS\""

mark_job_completed "run_tests"
