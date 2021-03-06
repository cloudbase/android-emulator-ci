#!/bin/bash

set +e

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

function prepare_emu_vm_shares () {
    log_summary "Exporting emulator vm log/results dirs."
    call_emu_vm_script "ensure_public_share" $EMU_VM_LOG_SHARE \
                                             $EMU_VM_LOG_DIR
    call_emu_vm_script "ensure_public_share" $EMU_VM_RESULTS_SHARE \
                                             $EMU_VM_TEST_RESULTS_DIR

    log_summary "Mounting emulator vm log/results dirs."
    mount_emu_vm_share $EMU_VM_LOG_SHARE $EMU_VM_LOCAL_LOG_MOUNT
    mount_emu_vm_share $EMU_VM_RESULTS_SHARE $EMU_VM_LOCAL_RESULTS_MOUNT
}

function cleanup_emu_vm_shares () {
    log_summary "Unmounting emulator vm shares."
    ensure_share_unmounted $EMU_VM_LOCAL_LOG_MOUNT
    ensure_share_unmounted $EMU_VM_LOCAL_RESULTS_MOUNT
}

if [[ -z $EMU_VM_IP ]]; then
    log_summary "Missing emulator vm ip. Skipped collecting emulator" \
                "vm logs."
else
    # This is highly likely to happen if the job fails early,
    # before the emulator VM boots.
    prepare_emu_vm_shares || \
        log_summary "Failed to prepare emulator VM shares."
fi

log_summary "Preparing log server packages dir."
ssh_log_srv "mkdir -p $LOG_SRV_JOB_PACKAGES_DIR"

log_summary "Transfering logs to log server."
scp_log_srv -r \
            "$JOB_LOG_DIR" \
            "$LOG_SRV_USERNAME@$LOG_SRV:$LOG_SRV_JOB_LOG_DIR"

if [[ ! -z $EMU_VM_IP ]]; then
    log_summary "Transfering test results to log server."

    # Ensuring that the mountpoint exists, even if the mount failed.
    mkdir -p $JOB_EMU_VM_RESULTS_DIR
    scp_log_srv -r \
                "$JOB_EMU_VM_RESULTS_DIR" \
                "$LOG_SRV_USERNAME@$LOG_SRV:$LOG_SRV_JOB_RESULTS_DIR"

    cleanup_emu_vm_shares
fi

mark_job_completed "collect_logs"
