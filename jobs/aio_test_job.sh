#!/bin/bash

set +e

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"

function create_environment () {
    $SCRIPT_DIR/create_environment.sh
}

function run_tests () {
    $SCRIPT_DIR/run_tests.sh
}

function collect_logs () {
    $SCRIPT_DIR/collect_logs.sh
}

function cleanup_environment () {
    $SCRIPT_DIR/cleanup_environment.sh
}

EXIT_CODE=1

create_environment && run_tests && EXIT_CODE=0
collect_logs || EXIT_CODE=1
cleanup_environment || EXIT_CODE=1

exit $EXIT_CODE
