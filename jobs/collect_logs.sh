#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

# At this point, we assume that the emulator build logs have already
# been fetched from the build vm and stored in the $JOB_STATE_DIR.

# The job entry point scripts are already logging there.

# We still have to fetch the logs and test results from the emulator
# test vm. We'll use SMB shares, for now mounting them in the JOB_STATE_DIR
# and then copying everything to the log server.

log_summary "Exporting emulator vm log/results dirs."
start_emu_vm_job "ensure_public_share" $EMU_VM_LOG_SHARE \
                                       $EMU_VM_LOG_DIR
start_emu_vm_job "ensure_public_share" $EMU_VM_RESULTS_SHARE \
                                       $EMU_VM_TEST_RESULTS_DIR

log_summary "Mounting emulator vm log/results dirs."
mount_emu_vm_share $EMU_VM_LOG_SHARE $EMU_VM_LOCAL_LOG_MOUNT
mount_emu_vm_share $EMU_VM_RESULTS_SHARE $EMU_VM_LOCAL_RESULTS_MOUNT

log_summary "Transfering logs to log server."
scp_log_srv -r \
            "$JOB_LOG_DIR" \
            "$LOG_SRV_USERNAME@$LOG_SRV:$LOG_SRV_JOB_LOG_DIR"

log_summary "Unmounting emulator vm shares."
ensure_share_unmounted $EMU_VM_LOCAL_LOG_MOUNT -f
ensure_share_unmounted $EMU_VM_LOCAL_RESULTS_MOUNT -f

mark_job_completed "collect_logs"
