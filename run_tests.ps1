# Requirements
# - Android Emulator unit tests package

Param(
    [Parameter(Mandatory=$true)]
    [string]$emulatorUnitTestsArchive
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config\global_config.ps1"

import-module "$scriptLocation\utils\all.psm1"

function extract_unit_tests() {
    ensure_dir_exists $emulatorUnitTestsDir

    log_message ("Extracting emulator unit tests archive: " +
                 "`"$emulatorUnitTestsArchive`' " +
                 "-> `"$emulatorUnitTestsDir`".")
    tar_msys xf (convert_to_msys_path $emulatorUnitTestsArchive) `
           -C (convert_to_msys_path $emulatorUnitTestsDir)
}

function prepare_adt_emu_tests() {
    git_clone_pull $adtInfraDir $adtInfraRepoUrl $adtInfraBranch `
                   -shallow $shallowGitClones
    pip install psutil
}

function run_gtests_from_dir($testdir, $resultDir, $pattern) {
    $testFailed = $false
    $testList = ls -Recurse $testdir | `
                ? { $_.Name -match $pattern }

    foreach($testBinary in $testList) {
        $testName = $testBinary.Name
        $testPath = $testBinary.FullName

        try {
            run_gtest $testPath $resultDir $unitTestSuiteTimeout
        }
        catch {
            # We'll continue to run tests.
            $errMsg = $_.Exception.Message
            log_message "$($testName) failed. Error: $errMsg"
            # TODO: keep better track of the failed tests.
            # We may consider using a JSON.
            $testFailed = $true

            echo $testName >> $failedTestListFile
            echo $errMsg >> $failedTestListFile
            echo "" >> $failedTestListFile
        }
    }

    if($testFailed) {
        throw "One or more unit tests have failed."
    }
}

function run_unit_tests() {
    log_message "Running unit tests."
    run_gtests_from_dir $emulatorUnitTestsDir `
                        $unitTestResultsDir "unittests.exe"
}

function run_adt_emu_tests() {
    log_message 'Running emulator integration tests from adt_infra.'
    $emuTestCfgDir = "$scriptLocation\config\emu_test"

    ensure_dir_exists $adtEmuTestResultDir
    python "$adtInfraDir\emu_test\dotest.py" `
        --file_pattern="test_boot.py" `
        --session_dir=$adtEmuTestResultDir `
        --config_file='$emuTestCfgDir\ui_cfg.csv' `
        --buildername="localhost"
        # --avd_list $testAvdName
}

rm $failedTestListFile -ErrorAction SilentlyContinue
ensure_dir_exists $unitTestResultsDir

extract_unit_tests
prepare_adt_emu_tests

# run_unit_tests
run_adt_emu_tests
