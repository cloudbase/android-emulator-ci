#!/bin/bash

set +e

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_summary "Unmounting emulator vm shares."
ensure_share_unmounted $EMU_VM_LOCAL_LOG_MOUNT
ensure_share_unmounted $EMU_VM_LOCAL_RESULTS_MOUNT

log_summary "Cleaning up local emulator packages."
rm -f "$JOB_PACKAGES_DIR/$EMULATOR_ARCHIVE_NAME"
rm -f "$JOB_PACKAGES_DIR/$UNITTESTS_ARCHIVE_NAME"

log_summary "Cleaning up builder vm: $BUILDER_VM_ID."
cleanup_vm $BUILDER_VM_ID

log_summary "Cleaning up emulator vm: $EMU_VM_ID."
cleanup_vm $EMU_VM_ID

mark_job_completed "cleanup_environment"
