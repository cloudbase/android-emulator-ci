Param(
    [Parameter(Mandatory=$true)]
    [string]$androidEmulatorArchive,
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config\global_config.ps1"

import-module "$scriptLocation\..\utils\windows\all.psm1"

function check_prerequisites() {
    log_message "Checking emulator prerequisites."
    $requiredFiles = @($androidEmulatorArchive)
    $requiredFiles | % { check_path $_ }
}

function extract_emulator_archive() {
    ensure_dir_empty $androidEmulatorDir
    # The tarball is expected to include the emulator files
    # in "android-*/tools/".
    if ($androidEmulatorArchive -notmatch "\.tar\.[a-z0-9]+$") {
        throw "The emulator archive is expected to be a tarball. " +
              "Was given: `"$androidEmulatorArchive`"."
    }

    log_message ("Extracting emulator archive: `"$androidEmulatorArchive`' " +
                 "-> `"$androidEmulatorHome`".")
    tar_msys xf (convert_to_msys_path $androidEmulatorArchive) `
           -C (convert_to_msys_path $androidEmulatorDir) `
           --strip-components 2
}

check_prerequisites

# The SDK manager may install the emulator as a dependency of other
# packages. We'll install it last, making sure that it doesn't get
# overridden.
# Also, by having this step decoupled, we may install the SDK
# while waiting for the actual emulator to build.
extract_emulator_archive
set_android_emulator_feature "WindowsHypervisorPlatform" "on"

add_to_env_path "$androidEmulatorDir"

ensure_binary_available "emulator"

create_avd $testAvdName $testAvdPackage $testAvdDevice $testAvdAbi
