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
    safe_exec "pip install psutil"
    safe_exec "pip install requests"

    # The emulator python test modules must be importable.
    add_to_env_path $adtInfraDir -var PYTHONPATH
}

function clear_test_stats() {
    $env:TEST_FAILED = "0"
    echo "" > $failedTestListFile
    echo "" > $executedTestListFile
}

function validate_test_run() {
    if ($env:TEST_FAILED -ne "0") {
        # TODO: We may actually list them.
        throw "One or more test suites have failed"
    }

    log_message "All the tests have passed."
}

function notify_starting_test($testDescription, $testType) {
    log_message "Running test: ($testType) $testDescription."

    echo "($testType) $testDescription" >> $executedTestListFile
}

function notify_successful_test($testDescription, $testType) {
    log_message "($testType) $testDescription passed."

    echo "($testType) $testDescription" >> $successfulTestListFile
}

function notify_failed_test($testDescription, $testType, $errMsg) {
    # We're going to resume running tests even if one of the suite fails,
    # throwing an error at the end of the run.
    $env:TEST_FAILED = "1"

    log_message "($testType) $testDescription failed. Error: $errMsg"

    # TODO: keep better track of the failed tests.
    # We may consider using a JSON.
    echo "($testType) $testDescription" >> $failedTestListFile
    echo $errMsg >> $failedTestListFile
    echo "" >> $failedTestListFile
}

function prepare_lib_paths() {
    log_message "Adding emulator library paths to %PATH%."
    foreach ($baseLibDir in @("$androidEmulatorDir\lib64",
                              "$androidEmulatorDir\lib")) {
        $libDirs = @(
            "$baseLibDir"
            "$baseLibDir\qt\lib"
            "$baseLibDir\gles_angle11"
            "$baseLibDir\gles_angle9"
            "$baseLibDir\gles_angle"
            "$baseLibDir\gles_swiftshader")
        $libDirs | % {add_to_env_path $_}
    }
}

function get_isolated_tests($testFileName, $isolatedTestsMapping) {
    $isolatedTests = @()
    foreach ($isolatedTestPattern in $isolatedTestsMapping.Keys) {
        if ($testFileName -match $isolatedTestPattern) {
            $isolatedTests += $isolatedTestsMapping[$isolatedTestPattern]
        }
    }
    $isolatedTests
}

function run_gtests_from_dir($testdir, $resultDir, $pattern,
                             $isolatedTestsMapping,
                             $runIsolatedTests,
                             $testType) {
    $testList = ls -Recurse $testdir | `
                ? { $_.Name -match $pattern }

    foreach($testBinary in $testList) {
        $testName = $testBinary.Name
        $testPath = $testBinary.FullName

        $isolatedTests = get_isolated_tests $testName $isolatedTestsMapping
        $testFilter = $isolatedTests -join ":"
        if (! $runIsolatedTests -and $testFilter) {
            $testFilter = "-$testFilter"
        }
        else {
            if (! $isolatedTests ) {
                # No isolated tests for this suite.
                continue
            }
        }

        try {
            notify_starting_test $testName $testType
            run_gtest $testPath $resultDir `
                      $unitTestSuiteTimeout $testFilter
            notify_successful_test $testName $testType
        }
        catch {
            $errMsg = $_.Exception.Message
            notify_failed_test $testName $testType $errMsg
        }
    }
}

function run_unit_tests() {
    log_message "Running unit tests."
    run_gtests_from_dir -testdir $emulatorUnitTestsDir `
                        -resultDir $unitTestResultsDir `
                        -pattern "unittests.exe" `
                        -isolatedTestsMapping $isolatedUnitTests `
                        -runIsolatedTests $false `
                        -testType "unittests"

    # Various tests that are known to crash or hang.
    log_message "Running isolated unit tests."
    run_gtests_from_dir -testdir $emulatorUnitTestsDir `
                        -resultDir $isolatedUnitTestResultsDir `
                        -pattern "unittests.exe" `
                        -isolatedTestsMapping $isolatedUnitTests `
                        -runIsolatedTests $true `
                        -testType "unittests_isolated"
}

function run_adt_emu_test_suite($testFileName) {
    log_message ("Running adt emulator tests from `"$testFileName`". " +
                 "Timeout: $integrationTestSuiteTimeout seconds. " +
                 "Instance boot timeout: $instanceBootTimeout seconds.")
    $emuTestCfgDir = "$scriptLocation\config\emu_test"
    $logFile = Join-Path $adtEmuTestResultDir `
                         ($testFileName.Replace(".py", "") + ".log")

    $cmd = ("cmd /c " +
            "'python `"$adtInfraDir\emu_test\dotest.py`" " +
            "--file_pattern=`"$testFileName`" " +
            "--skip-adb-perf " +
            "--test_dir=$adtEmuTestResultDir " +
            "--session_dir=$adtEmuTestResultDir " +
            "--config_file=`"$emuTestCfgDir\test_cfg.csv`" " +
            "--buildername=`"localhost`" " +
            "--timeout=$($integrationTestSuiteTimeout * $softTimeoutRatio) " +
            "--boot_time=$instanceBootTimeout >> $logFile 2>&1'")
            # --avd_list $testAvdName
    log_message "Executing $cmd"
    iex_with_timeout $cmd $integrationTestSuiteTimeout
}

function run_adt_emu_tests() {
    log_message 'Running emulator integration tests from adt_infra.'
    ensure_dir_empty $adtEmuTestResultDir

    foreach ($testFileName in $adtEmuEnabledTests) {
        try {
            notify_starting_test "$testFileName" "adt_emu_test"
            run_adt_emu_test_suite $testFileName
            notify_successful_test "$testFileName" "adt_emu_test"
        }
        catch {
            $errMsg = $_.Exception.Message
            notify_failed_test "$testFileName" "adt_emu_test" $errMsg
        }
    }
}


rm $failedTestListFile -ErrorAction SilentlyContinue
ensure_dir_exists $unitTestResultsDir
ensure_dir_exists $isolatedUnitTestResultsDir

extract_unit_tests
prepare_adt_emu_tests
prepare_lib_paths

clear_test_stats

run_unit_tests
run_adt_emu_tests

validate_test_run
