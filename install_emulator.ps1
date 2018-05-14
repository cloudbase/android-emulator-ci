# Requirements
# - Android sdk archive
# - Android emulator archive
# - 7-zip
# - jre 1.8 (1.10 doesn't work)

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

set_env "ANDROID_SDK_ROOT" $androidRootDir
set_env "ANDROID_EMULATOR_HOME" $androidEmulatorHome

function install_sdk_packages() {
    $sdkPackagesFile = "$scriptLocation\sdk_packages.txt"
    if (! (test-path $sdkPackagesFile)) {
        $err = "Could not find SDK packages file. Expecting " +
               "to find it at $sdkPackagesFile"
        throw $err
    }

    gc .\sdk_packages.txt | `
        % {$_.Trim() } | `
        ? { -not $_.StartsWith("#") } | `
         % {install_android_sdk_package $_}
}

install_sdk_packages
