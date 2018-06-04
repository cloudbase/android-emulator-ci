#!/bin/bash

set -eE

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"
source "$SCRIPT_DIR/utils.sh"

setup_logging $JOB_LOG_DIR

mkdir -p $JOB_BUILD_LOG_DIR
mkdir -p $JOB_EMU_VM_LOG_DIR

log_summary "Starting build job."
nohup $SCRIPT_DIR/build_emulator.sh &> $JOB_BUILD_LOG_DIR/build_emulator.log &
pid_build_job=$!

log_summary "Preparing emulator test environment."
nohup $SCRIPT_DIR/create_emulator_vm.sh &> $JOB_EMU_VM_LOG_DIR/create_emulator_vm.log &
pid_emu_vm_job=$!

log_summary "Wating for parallel init jobs."

finished_build_job=0
finished_emu_vm_job=0

TIME_COUNT=0
PROC_COUNT=2

while [[ $TIME_COUNT -lt $CREATE_ENVIRONMENT_TIMEOUT ]] \
        && [[ $PROC_COUNT -gt 0 ]]; do

    if [[ $finished_build_job -eq 0 ]]; then
        ps -p $pid_build_job > /dev/null 2>&1 || finished_build_job=$?
        [[ $finished_build_job -ne 0 ]] \
            && PROC_COUNT=$(( $PROC_COUNT - 1 )) \
            && log_summary "Finished building the emulator."
    fi
    if [[ $finished_emu_vm_job -eq 0 ]]; then
        ps -p $pid_emu_vm_job > /dev/null 2>&1 || finished_emu_vm_job=$?
        [[ $finished_emu_vm_job -ne 0 ]] \
            && PROC_COUNT=$(( $PROC_COUNT - 1 )) \
            && log_summary "Finished preparing emulator VM."
    fi

    if [[ $PROC_COUNT -gt 0 ]]; then
        sleep $JOB_POLL_INTERVAL
        TIME_COUNT=$(( $TIME_COUNT + $JOB_POLL_INTERVAL ))
    fi
done

log_summary "Finished waiting for the parallel init jobs."
log_summary "After $TIME_COUNT seconds, there are $PROC_COUNT still running."

if [[ $PROC_COUNT -gt 0 ]]; then
    log_summary "Not all build jobs finished in time. Killing pending jobs."

    if [[ $finished_build_job -eq 0 ]]; then
        log_summary "Killing build job."
        kill -9 $pid_build_job &> /dev/null
    fi

    if [[ $finished_emu_vm_job -eq 0 ]]; then
        log_summary "Killing emu vm init job."
        kill -9 $pid_emu_vm_job &> /dev/null
    fi

    die "Timeout occured while waiting for init jobs."
fi

log_summary "Transfering the emulator archive."
ps_emu_vm "Invoke-WebRequest -Uri $EMULATOR_ARCHIVE_URL" \
          "-OutFile $EMU_VM_EMULATOR_ARCH_PATH"

log_summary "Transfering the unittests archive."
ps_emu_vm "Invoke-WebRequest -Uri $UNITTESTS_ARCHIVE_URL" \
          "-OutFile $EMU_VM_UNITTESTS_ARCH_PATH"

log_summary "Installing the emulator."
ps_emu_vm "$EMU_VM_SCRIPTS_DIR\test_host\install_emulator.ps1" \
          "-androidEmulatorArchive $EMU_VM_EMULATOR_ARCH_PATH"

log_summary "Finished creating test environment."
