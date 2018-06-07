#!/bin/bash

set +e

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/job.rc"

function create_environment () {
    $SCRIPT_DIR/create_environment.sh
}

function run_tests () {
    if [ ! -z $SKIP_TESTS ]; then
        $SCRIPT_DIR/run_tests.sh
    else
        echo "Skipping tests."
    fi
}

function collect_logs () {
    $SCRIPT_DIR/collect_logs.sh
}

function cleanup_environment () {
    $SCRIPT_DIR/cleanup_environment.sh
}

TESTS_PASSED=0

create_environment && run_tests && TESTS_PASSED=1
collect_logs
cleanup_environment

exit $TESTS_PASSED