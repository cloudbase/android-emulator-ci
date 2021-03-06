#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

log_ci_scripts_git_info

log_summary "Prebuilt emulator archive url: $PREBUILT_EMULATOR_ARCHIVE_URL"
log_summary "Prebuilt unit tests url: $PREBUILT_ARCHIVE_URL"

log_summary "Starting emulator build job."
LOG_SCRIPT_NAME=1 nohup $SCRIPT_DIR/build_emulator.sh &
pid_build_job=$!

log_summary "Preparing emulator test environment."
LOG_SCRIPT_NAME=1 nohup $SCRIPT_DIR/create_emulator_vm.sh &
pid_emu_vm_job=$!

log_summary "Wating for parallel init jobs."

finished_build_job=0
finished_emu_vm_job=0

TIME_COUNT=0
PROC_COUNT=2

function kill_pending_jobs () {
    log_summary "Killing pending jobs."

    kill_if_running $pid_build_job "Killing build job."
    kill_if_running $pid_emu_vm_job "Killing emu vm init job."
}

function validate_completed_job () {
    local JOB_NAME=$1

    check_job_completed $1 || \
        (kill_pending_jobs ; die "Job \"$JOB_NAME\" failed.")
    log_summary "Job \"$JOB_NAME\" completed successfully."
}

while [[ $TIME_COUNT -lt $CREATE_ENVIRONMENT_TIMEOUT ]] \
        && [[ $PROC_COUNT -gt 0 ]]; do

    if [[ $finished_build_job -eq 0 ]]; then
        check_running_pid $pid_build_job || finished_build_job=1
        [[ $finished_build_job -ne 0 ]] \
            && PROC_COUNT=$(( $PROC_COUNT - 1 )) \
            && validate_completed_job "build_emulator"
    fi
    if [[ $finished_emu_vm_job -eq 0 ]]; then
        check_running_pid $pid_emu_vm_job || finished_emu_vm_job=1
        [[ $finished_emu_vm_job -ne 0 ]] \
            && PROC_COUNT=$(( $PROC_COUNT - 1 )) \
            && validate_completed_job "create_emulator_vm"
    fi

    if [[ $PROC_COUNT -gt 0 ]]; then
        sleep $JOB_POLL_INTERVAL
        TIME_COUNT=$(( $TIME_COUNT + $JOB_POLL_INTERVAL ))
    fi
done

log_summary "Finished waiting for the parallel init jobs."
log_summary "After $TIME_COUNT seconds, there are $PROC_COUNT still running."

if [[ $PROC_COUNT -gt 0 ]]; then
    log_summary "Not all build jobs finished in time."
    kill_pending_jobs
    die "Timeout occured while waiting for init jobs."
fi

# Reload the job rc file, it should now include the instance ids,
# among others.
source $JOB_STATE_RC

if str_to_bool $SKIP_BUILD && [ -z $PREBUILT_EMULATOR_ARCHIVE_URL ]; then
    log_summary "WARNING: The emulator build was skipped yet no" \
                "emulator archive was specified. The upstream" \
                "emulator will be used instead."
else
    LOG_SCRIPT_NAME=1 $SCRIPT_DIR/install_emulator.sh
fi

log_summary "Finished creating test environment."

mark_job_completed "create_environment"
