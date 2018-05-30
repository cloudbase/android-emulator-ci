basedir_utils=$(dirname "$0")
source "$basedir_utils/exec.sh"

TIMESTAMP_FORMAT=${TIMESTAMP_FORMAT:-"+%F_%H:%M:%S%:::z"}

function log_message () {
    echo -e "[$(date "+$TIMESTAMP_FORMAT")] $@"
}

function log_warning () {
    log_message "WARNING: $@"
}

function log_summary () {
    # Use this function to log certain build events, both to the
    # original stdout, as well as the log file.
    if [ -z $LOGFILE_CONFIGURED ]; then
        log_message "$@" >> $LOG_SUMMARY_FILE
    fi

    log_message "$@"
}

function err_trap () {
    local r=$?
    set +o xtrace

    log_summary "${0##*/} failed."

    exit $r
}

function die () {
    set +o xtrace
    log_summary "$@ Full log in $BUILD_LOG"
    exit 1
}

function setup_logging () {
    if [ ! -z $LOGFILE_CONFIGURED ]; then
        # Logging already configured.
        return
    fi

    local default_log_name=$(basename $0 | sed 's/\..*//')
    local log_dir=$1
    local log_name=${2:-default_log_name}

    set -o xtrace

    if [ -z $log_dir ]; then
        log_message "Log dir not specified."
        return
    fi

    mkdir -p $log_dir

    export LOG_FILE="$log_dir/$log_name.txt"
    export LOG_SUMMARY_FILE="$log_dir/$log_name.summary.txt"

    exec &> >(tee -a "$LOG_FILE")
}

function set_exit () {
    trap err_trap ERR
    set -eE
}

function ensure_env_vars_set () {
    MISSING_VARS=()

    while test $# -gt 0
    do
        var=$1
        
        if [ -z ${!var} ]; then
            MISSING_VARS+=($var)
        fi
        shift
    done

    die "The following environment variables must " \
        "be set: ${MISSING_VARS[@]}"
}
