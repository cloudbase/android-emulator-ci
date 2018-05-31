#!/bin/bash

TIMESTAMP_FORMAT=${TIMESTAMP_FORMAT:-"%F_%H:%M:%S%:::z"}

set -o pipefail

function log_message () {
    echo -e "[$(date "+$TIMESTAMP_FORMAT")] $@"
}

function log_warning () {
    log_message "WARNING: $@"
}

function log_summary () {
    local _XTRACE=$(set +o | grep xtrace)
    set +o xtrace
    log_message "$@"

    if [ ! -z $LOGGING_CONFIGURED ]; then
        log_message "$@" >&3
        log_message "$@" >> $LOG_SUMMARY_FILE
    fi

    # restore xtrace
    $_XTRACE
}

trap err_trap ERR
function err_trap () {
    local r=$?
    set +o xtrace

    log_summary "${0##*/} failed."
    if [ ! -z $LOGGING_CONFIGURED ]; then
        log_summary "Full log: $LOG_FILE."
        tail -n 15 $LOG_FILE >&3
    fi

    exit $r
}

function die () {
    set +o xtrace
    log_summary "$@"

    if [ ! -z $LOGGING_CONFIGURED ]; then
        log_summary "Full log: $LOG_FILE."
    fi

    exit 1
}

function setup_logging () {
    if [ ! -z $LOGGING_CONFIGURED ]; then
        # Logging already configured.
        return
    fi

    local default_log_name=$(basename $0 | sed 's/\..*//')
    local log_dir=$1
    local log_name=${2:-$default_log_name}

    if [ -z $log_dir ]; then
        log_message "Log dir not specified."
        return
    fi

    mkdir -p $log_dir

    export LOG_FILE="$log_dir/$log_name.log"
    export LOG_SUMMARY_FILE="$log_dir/$log_name.summary.log"

    # Save original fds.
    exec 3>&1
    exec 4>&2

    exec 1> $LOG_FILE 2>&1
    rm -f $LOG_SUMMARY_FILE

    set -o xtrace
    export LOGGING_CONFIGURED="1"
}

function ensure_env_vars_set () {
    local MISSING_VARS=()

    while test $# -gt 0
    do
        local var=$1

        if [[ -z ${!var} ]]; then
            MISSING_VARS+=($var)
        fi
        shift
    done

    if [ ! -z $MISSING_VARS ]; then
        die "The following environment variables must" \
            "be set: ${MISSING_VARS[@]}"
    fi
}
