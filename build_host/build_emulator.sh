#!/bin/bash

set -eE

# Source build.rc first.
# This script was initially used by a docker image,
# to which we may return at some point.
SCRIPT_DIR=$(dirname "$BASH_SOURCE")

source "$SCRIPT_DIR/build.rc"
source "$SCRIPT_DIR/../utils/linux/all.sh"

setup_logging $BUILD_LOG_DIR

REQUIRED_ENV_VARS=(AOSP_DIR AOSP_BRANCH \
                   BUILD_LOG_DIR OUTPUT_PACKAGE_DIR \
                   UNITTESTS_ARCHIVE_NAME)
ensure_vars_set ${REQUIRED_ENV_VARS[@]}

# We'll try to use the same volume as much as possible.
TMP_PKG_DIR="$OUTPUT_PACKAGE_DIR/ae_build_tmp"
log_message "Using temporary dir: $TMP_PKG_DIR"
ensure_dir_empty $TMP_PKG_DIR

function ensure_repo_installed () {
    # Fetch the Google "repo" tool, which is
    # used to manage dependent git repos.
    if [ ! $(which repo 2> /dev/null) ]; then
        local REPO_URL="https://storage.googleapis.com/git-repo-downloads/repo"
        sudo curl $REPO_URL -o /usr/bin/repo
        sudo chmod a+x /usr/bin/repo;
    fi
}

function sync_aosp_tree () {
    log_summary "Preparing AOSP tree."

    if [ -d $AOSP_DIR ]; then
        echo "AOSP DIR already exists: $AOSP_DIR."
    fi
    mkdir -p $AOSP_DIR

    ensure_repo_installed

    pushd $AOSP_DIR

    # TODO: allow applying extra patches.
    time repo init \
        -u https://android.googlesource.com/platform/manifest \
        -b $AOSP_BRANCH --depth=1
    time repo sync --current-branch

    popd
}

function apply_emulator_patch () {
    local GERRIT_REFSPEC="$GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER"

    log_summary "Applying patch $GERRIT_REFSPEC."

    pushd $AOSP_DIR/external/qemu
    repo download platform/external/qemu $GERRIT_REFSPEC
    popd
}

function ensure_ccache_dir () {
    if [ ! -z $CCACHE_DIR ]; then
        mkdir -p $CCACHE_DIR
    else
        echo "CCACHE_DIR not set, disabling ccache."
        export CCACHE_DISABLE="1"
    fi
}

function build_emulator () {
    log_summary "Starting build."

    ensure_ccache_dir

    # Let's make it easier to identify the output package.
    # We'll explicitly set those values, using the defaults.
    PKG_PREFIX="android-emulator"
    PKG_REVISION=$(date +%Y%m%d)
    EXPECTED_AE_PACKAGE="$TMP_PKG_DIR/$PKG_PREFIX-$PKG_REVISION-windows.tar.bz2"

    BUILD_ARGS="$ANDROID_BUILD_ARGS --package-dir=$TMP_PKG_DIR"
    BUILD_ARGS="$BUILD_ARGS --package-prefix=$PKG_PREFIX"
    BUILD_ARGS="$BUILD_ARGS --revision=$PKG_REVISION"

    pushd $AOSP_DIR/external/qemu
    log_git_info

    # TODO: Drop this once it merges upstream. We need it in order
    # to do x86/x64 only builds.
    git fetch https://android.googlesource.com/platform/external/qemu \
              refs/changes/45/708045/1 && git cherry-pick FETCH_HEAD

    time android/scripts/package-release.sh $BUILD_ARGS

    OUT_PACKAGES=$(find $TMP_PKG_DIR -type f)
    # We'll log all the resulted files, maybe the "package-release.sh script"
    # will change at some point.
    log_summary "Finished building Android Emulator."
    log_message "Output packages: $OUT_PACKAGES"

    if [ ! -f $EXPECTED_AE_PACKAGE ]; then
        die "Build failed. Could not find expected emulator package:" \
            "$EXPECTED_AE_PACKAGE."
    fi

    AE_PACKAGE="$OUTPUT_PACKAGE_DIR/$EMULATOR_ARCHIVE_NAME"
    mv $EXPECTED_AE_PACKAGE $AE_PACKAGE
    log_summary "Android emulator archive: $AE_PACKAGE"

    popd
}

function package_unitests () {
    log_summary "Packaging unit tests."

    UNITTESTS_PACKAGE_ARCHIVE="$OUTPUT_PACKAGE_DIR/$UNITTESTS_ARCHIVE_NAME"

    pushd $AOSP_DIR/external/qemu/objs
    TMP_FILE_LIST=$(mktemp)
    find . -name "*unittests*" | grep -v "/build" > $TMP_FILE_LIST
    # Those libs get explicity omitted when packaging the emulator,
    # while being required by some of the unit tests.
    find . -name "*emugl_test_shared_library*" | \
        grep -v "/build" >> $TMP_FILE_LIST
    find . | grep testdata >> $TMP_FILE_LIST

    tar -czf $UNITTESTS_PACKAGE_ARCHIVE -T $TMP_FILE_LIST

    log_summary "Android Emulator unit tests archive:" \
                "$UNITTESTS_PACKAGE_ARCHIVE"

    rm -f "$TMP_FILE_LIST"
    popd
}

function install_deps () {
    log_summary "Installing dependencies."

    # TODO: apt locks may be in place (especially as
    # cloud init is still running). We should wait for
    # those locks to be released.
    sudo apt-get update
    sudo apt-get install -y $EXTRA_PACKAGES
}

if [[ $SKIP_DEPS == "1" ]]; then
    log_summary "Skipped installing dependencies."
else
    install_deps
fi

set_git_ci_creds

if [[ $SKIP_SYNC_AOSP == "1" ]]; then
    log_summary "Skipped syncing AOSP tree."
else
    sync_aosp_tree
fi

if [ -z $GERRIT_CHANGE_NUMBER ] || [ -z $GERRIT_PATCHSET_NUMBER ]; then
    log_summary "Missing gerrit change/patchset. No patch to apply."
else
    apply_emulator_patch
fi

if [[ $SKIP_BUILD == "1" ]]; then
    log_summary "Skipped building the emulator."
else
    build_emulator
    package_unitests
fi

rm -rf $TMP_PKG_DIR
