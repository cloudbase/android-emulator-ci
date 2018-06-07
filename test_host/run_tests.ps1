# Requirements
# - Android Emulator unit tests package

Param(
    [Parameter(Mandatory=$true)]
    [string]$emulatorUnitTestsArchive
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config\global_config.ps1"

import-module "$scriptLocation\..\utils\windows\all.psm1"

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

function clear_test_stats() {
    $env:TEST_FAILED = $false
    echo "" > $failedTestListFile
    echo "" > $executedTestListFile
}

function validate_test_run() {
    if ($env:TEST_FAILED) {
        # TODO: We may actually list them.
        throw "One or more test suites have failed"
    }

    log_message "All the tests have passed."
}

function notify_starting_test($testDescription, $testType) {
    log_message "Running test: ($testType) $testDescription."

    echo "($testType) $testDescription" >> $executedTestListFile
}

function notify_failed_test($testDescription, $testType, $errMsg) {
    # We're going to resume running tests even if one of the suite fails,
    # throwing an error at the end of the run.
    $env:TEST_FAILED = $true

    log_message "($testType) $testDescription failed. Error: $errMsg"

    # TODO: keep better track of the failed tests.
    # We may consider using a JSON.
    echo "($testType) $testDescription" >> $failedTestListFile
    echo $errMsg >> $failedTestListFile
    echo "" >> $failedTestListFile
}

function run_gtests_from_dir($testdir, $resultDir, $pattern) {
    $testList = ls -Recurse $testdir | `
                ? { $_.Name -match $pattern }

    foreach($testBinary in $testList) {
        $testName = $testBinary.Name
        $testPath = $testBinary.FullName

        try {
            notify_starting_test $testName "unittest"
            run_gtest $testPath $resultDir $unitTestSuiteTimeout
        }
        catch {
            $errMsg = $_.Exception.Message
            notify_failed_test $testName "unittest" $errMsg
        }
    }
}

function run_unit_tests() {
    log_message "Running unit tests."
    run_gtests_from_dir $emulatorUnitTestsDir `
                        $unitTestResultsDir "unittests.exe"
}

function run_adt_emu_test_suite($testfilePattern) {
    log_message ("Running adt emulator tests from `"$testfilePattern`". " +
                 "Timeout: $integrationTestSuiteTimeout seconds. " +
                 "Instance boot timeout: $instanceBootTimeout seconds.")
    $emuTestCfgDir = "$scriptLocation\config\emu_test"

    $cmd = ("cmd /c " +
            "python `"$adtInfraDir\emu_test\dotest.py`" " +
            "--file_pattern=`"$testfilePattern`" " +
            "--test_dir=$adtEmuTestResultDir " +
            "--session_dir=$adtEmuTestResultDir " +
            "--config_file=`"$emuTestCfgDir\test_cfg.csv`" " +
            "--buildername=`"localhost`" " +
            "--timeout=$($integrationTestSuiteTimeout * $softTimeoutRatio) " +
            "--boot_time=$instanceBootTimeout >> $adtEmuTestLog 2>&1")
            # --avd_list $testAvdName
    log_message "Executing $cmd"
    iex_with_timeout $cmd $integrationTestSuiteTimeout
}

function run_adt_emu_tests() {
    log_message 'Running emulator integration tests from adt_infra.'
    ensure_dir_empty $adtEmuTestResultDir

    foreach ($testfilePattern in $adtEmuEnabledTests) {
        try {
            notify_starting_test "$testfilePattern" "adt_emu_test"
            run_adt_emu_test_suite $testfilePattern
        }
        catch {
            $errMsg = $_.Exception.Message
            notify_failed_test "$testfilePattern" "adt_emu_test" $errMsg
        }
    }
}


rm $failedTestListFile -ErrorAction SilentlyContinue
ensure_dir_exists $unitTestResultsDir

extract_unit_tests
prepare_adt_emu_tests

clear_test_stats

run_unit_tests
run_adt_emu_tests

validate_test_run
