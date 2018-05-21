# Requirements
# - Android sdk archive
# - Android emulator archive
# - msys
# - jre 1.8 (1.10 doesn't work)

Param(
    [Parameter(Mandatory=$true)]
    [string]$emulatorUnitTestsArchive
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"

import-module "$scriptLocation\utils\all.psm1"

function extract_unit_tests() {
    ensure_dir_exists $emulatorUnitTestsDir

    log_message ("Extracting emulator unit tests archive: " +
                 "`"$emulatorUnitTestsArchive`' " +
                 "-> `"$emulatorUnitTestsDir`".")
    tar_msys xf (convert_to_msys_path $emulatorUnitTestsArchive) `
           -C (convert_to_msys_path $emulatorUnitTestsDir)
}

function run_unit_tests() {
    log_message "Running unit tests."

    $testFailed = $false
    $testList = ls -Recurse $emulatorUnitTestsDir | `
                ? { $_.Name -match "unittests.exe" }

    foreach($testBinary in $testList) {
        try {
            run_gtest $testBinary.FullName $unitTestResultsDir
        }
        catch {
            # TODO: keep better track of the failed tests.
            $testFailed = $true
            echo $testBinary >> failedTestListFile
        }
    }

    if($testFailed) {
        throw "One or more unit tests has failed."
    }

    log_message "All the unit tests have passed."
}

unitTestResultsDir $unitTestResultsDir

extract_unit_tests
run_unit_tests
