# Requirements
# - Android sdk archive
# - Android emulator archive
# - msys
# - jre 1.8 (1.10 doesn't work)

Param(
    [Parameter(Mandatory=$true)]
    [string]$androidSdkArchive,
    [Parameter(Mandatory=$true)]
    [string]$androidEmulatorArchive,
    [bool]$skipCleanup=$false
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"

import-module "$scriptLocation\utils\all.psm1"

Start-Transcript -path "$logDir\install_emulator.log" -append

if (!(check_elevated) ){
    # We may need to run some installers, create some symlinks.
    throw "This script requires elevated privileges."
}

function check_prerequisites() {
    log_message "Checking prerequisites."
    $requiredFiles = @($androidSdkArchive, $androidEmulatorArchive)
    $requiredFiles | % { check_path $_ }

    check_windows_feature "HypervisorPlatform"

    $javaHome = $env:JAVA_HOME
    if (!($javaHome)) {
        throw "JAVA_HOME is not set. Please install JRE/JDK 8."
    }

    check_path $env:JAVA_HOME
    check_path $msysBinDir
}

function extract_sdk_archive() {
    if ($androidSdkArchive -notmatch "\.zip$") {
        throw ("The SDK archive is expected to be a .zip. " +
               "Was given: `"$androidSdkArchive`".")
    }
    extract_zip $androidSdkArchive $androidSdkRoot
}

function extract_emulator_archive() {
    ensure_dir_empty $androidEmulatorDir
    # The archive is expected to contain a single top dir which includes the
    # emulator files.
    if ($androidEmulatorArchive -notmatch "\.tar\.[a-z0-9]+$") {
        throw "The emulator archive is expected to be a tarball. " +
              "Was given: `"$androidEmulatorArchive`"."
    }

    log_message ("Extracting emulator archive: `"$androidEmulatorArchive`' " +
                 "-> `"$androidEmulatorHome`".")
    tar_msys xf (convert_to_msys_path $androidEmulatorArchive) `
           -C (convert_to_msys_path $androidEmulatorDir) `
           --strip-components 1
}

function install_sdk_packages() {
    $sdkPackagesFile = "$scriptLocation\sdk_packages.txt"
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
extract_emulator_archive

# Some of the SDK tools may ignore the environment variable or explicitly
# specified paths, and still use this one. For this reason, we'll ensure
# that it links to our avd dir, which may reside on a different disk.
ensure_symlink $androidEmulatorHome $androidDefaultHomeDir -isDir $true

accept_sdk_licenses
install_sdk_packages
set_android_emulator_feature "WindowsHypervisorPlatform" "on"

create_avd $testAvdName $testAvdPackage $testAvdDevice $testAvdAbi

stop-transcript
