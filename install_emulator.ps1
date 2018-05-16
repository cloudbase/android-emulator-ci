# Requirements
# - Android sdk archive
# - Android emulator archive
# - 7-zip
# - jre 1.8 (1.10 doesn't work)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

if (!(check_elevated) ){
    # We may need to run some installers, create some symlinks.
    throw "This script requires elevated privileges."
}

set_env "ANDROID_SDK_ROOT" $androidRootDir
set_env "ANDROID_EMULATOR_HOME" $androidEmulatorHome

function install_sdk_packages() {
    $sdkPackagesFile = "$scriptLocation\sdk_packages.txt"
    if (! (test-path $sdkPackagesFile)) {
        $err = "Could not find SDK packages file. Expecting " +
               "to find it at $sdkPackagesFile"
        throw $err
    }

    gc $sdkPackagesFile | `
        % {$_.Trim() } | `
        ? { -not $_.StartsWith("#") } | `
         % {install_android_sdk_package $_}
}

# Some of the SDK tools may ignore the environment variable or explicitly
# specified paths, and still use this one. For this reason, we'll ensure
# that it links to our avd dir, which may reside on a different disk.
ensure_symlink $androidEmulatorHome $androidDefaultHomeDir -isDir $true
install_sdk_packages
create_avd $testAvdName $testAvdPackage $testAvdDevice $testAvdAbi
