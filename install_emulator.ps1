# Requirements
# - Android sdk archive
# - Android emulator archive
# - 7-zip
# - jre 1.8 (1.10 doesn't work)

Param(
    [Parameter(Mandatory=$true)]
    [string]$androidSdkArchive;
    [Parameter(Mandatory=$true)]
    [string]$androidEmulatorArchive;
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

if (!(check_elevated) ){
    # We may need to run some installers, create some symlinks.
    throw "This script requires elevated privileges."
}

function install_sdk_packages() {
    $sdkPackagesFile = "$scriptLocation\sdk_packages.txt"
    if (! (test-path $sdkPackagesFile)) {
        throw ("Could not find SDK packages file. Expecting " +
               "to find it at $sdkPackagesFile")
    }

    gc $sdkPackagesFile | `
        % {$_.Trim() } | `
        ? { -not $_.StartsWith("#") } | `
        % {install_android_sdk_package $_}
}

function check_prerequisites() {
    log_message "Checking prerequisites."
    $requiredFiles = @($androidSdkArchive, $androidEmulatorArchive)
    foreach($file in $requiredFiles) {
        check_path $file
    }

    check_windows_feature "HypervisorPlatform"
}

check_prerequisites

set_env "ANDROID_SDK_ROOT" $androidSdkRoot
set_env "ANDROID_EMULATOR_HOME" $androidEmulatorHome

# Some of the SDK tools may ignore the environment variable or explicitly
# specified paths, and still use this one. For this reason, we'll ensure
# that it links to our avd dir, which may reside on a different disk.
ensure_symlink $androidEmulatorHome $androidDefaultHomeDir -isDir $true
install_sdk_packages
create_avd $testAvdName $testAvdPackage $testAvdDevice $testAvdAbi
