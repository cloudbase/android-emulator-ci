# See the project readme for requirements.
# We'll validate test requirements as well at this stage.

Param(
    [Parameter(Mandatory=$true)]
    [string]$androidSdkArchive,
    [bool]$skipCleanup=$false
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config\global_config.ps1"

import-module "$scriptLocation\utils\all.psm1"

if (!(check_elevated) ){
    # We may need to run some installers, create some symlinks.
    throw "This script requires elevated privileges."
}

function check_prerequisites() {
    log_message "Checking Android SDK prerequisites."
    $requiredFiles = @($androidSdkArchive)
    $requiredFiles | % { check_path $_ }
}

function extract_sdk_archive() {
    if ($androidSdkArchive -notmatch "\.zip$") {
        throw ("The SDK archive is expected to be a .zip. " +
               "Was given: `"$androidSdkArchive`".")
    }
    extract_zip $androidSdkArchive $androidSdkRoot
}

function install_sdk_packages() {
    $sdkPackagesFile = "$scriptLocation\config\sdk_packages.txt"
    check_path $sdkPackagesFile

    gc $sdkPackagesFile | `
        % {$_.Trim() } | `
        ? { -not $_.StartsWith("#") } | `
        ? {$_} | `
        % {install_android_sdk_package $_}
}

check_prerequisites

if (!($skipCleanup)){
    . "$scriptLocation\remove_emulator.ps1"
}

set_env "ANDROID_SDK_ROOT" $androidSdkRoot
set_env "ANDROID_EMULATOR_HOME" $androidEmulatorHome
set_env "ANDROID_EMULATOR_LAUNCHER_DIR" $androidEmulatorDir

ensure_dir_exists $androidRootDir
ensure_dir_exists $androidEmulatorHome

extract_sdk_archive

# Some of the SDK tools may ignore the environment variable or explicitly
# specified paths, and still use this one. For this reason, we'll ensure
# that it links to our avd dir, which may reside on a different disk.
ensure_symlink $androidEmulatorHome $androidDefaultHomeDir -isDir $true

accept_sdk_licenses
install_sdk_packages

# Some of the emulator tests require those to be set in %PATH%.
# We'll take care of it at this stage.
add_to_env_path "$androidPlatformToolsDir"
add_to_env_path "$androidSdkToolsBinDir"

# Some quick sanity checks, validating the sdk executables.
ensure_binary_available "adb"
ensure_binary_available "avdmanager.bat"
