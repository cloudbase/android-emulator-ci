#!/bin/bash

SCRIPT_DIR=$(dirname "$BASH_SOURCE")
PROJ_DIR="$SCRIPT_DIR/../"

FAILED=0

function check_local_command_substitution() {
    echo "Checking for misuse of local variables and command substitution."

    local occurrences
    occurrences=$(grep -RE 'local [a-zA-Z0-9_]+=(\$\(|`)' $PROJ_DIR)
    if [[ ! -z $occurrences ]]; then
        FAILED=1
        echo -e "Local variables are used in conjunction with command" \
            "substitution. This will prevent non-zero return codes from" \
            "being intercepted. Please declare the local variables" \
            "separately.\n"
        echo "$occurrences"
    fi
}

check_local_command_substitution

exit $FAILED
