# Requirements
# - Android Emulator unit tests package

Param(
    [Parameter(Mandatory=$true)]
    [string]$emulatorUnitTestsArchive,
    [string]$adtEmuEnabledTests
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
    # TODO: move this to a separate script so that we may run
    # it when setting up the environment.
    git_clone_pull $adtInfraDir $adtInfraRepoUrl $adtInfraBranch `
                   -shallow $shallowGitClones
    safe_exec "pip install psutil"
    safe_exec "pip install requests"
    safe_exec "pip install os_testr"
    safe_exec "pip install python-dateutil"

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
                             $testType,
                             $subunitOutFile) {
    $testList = ls -Recurse $testdir | `
                ? { $_.Name -match $pattern }

    foreach($testBinary in $testList) {
        $testName = $testBinary.Name
        $testPath = $testBinary.FullName

        $isolatedTests = get_isolated_tests $testName $isolatedTestsMapping
        $testFilter = $isolatedTests -join ":"
        if ($runIsolatedTests -and (! $testFilter)) {
            # No isolated tests for this suite.
            continue
        }
        if ((! $runIsolatedTests) -and $testFilter) {
            $testFilter = "-$testFilter"
        }

        try {
            notify_starting_test $testName $testType
            run_gtest_subunit `
                $testPath $resultDir $unitTestSuiteTimeout $testFilter `
                $subunitOutFile
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
                        -testType "unittests" `
                        -subunitOutFile $unitTestSubunitResults

    # Various tests that are known to crash or hang.
    log_message "Running isolated unit tests."
    run_gtests_from_dir -testdir $emulatorUnitTestsDir `
                        -resultDir $isolatedUnitTestResultsDir `
                        -pattern "unittests.exe" `
                        -isolatedTestsMapping $isolatedUnitTests `
                        -runIsolatedTests $true `
                        -testType "unittests_isolated" `
                        -subunitOutFile $unitTestSubunitResults

    generate_subunit_report $unitTestSubunitResults $testResultsDir `
                            "unittest_results"
}

function run_adt_emu_test_suite($testFileName) {
    # For convenience reasons, we won't enforce the extension to be set.
    $testSuiteName = $testFileName.Replace(".py", "")
    $testFileName = $testSuiteName + ".py"
    $testTimeout = $customTestTimeout[$testSuiteName]
    if (! $testTimeout) {
        $testTimeout = $integrationTestSuiteTimeout
    }

    log_message ("Running adt emulator tests from `"$testSuiteName`". " +
                 "Timeout: $testTimeout seconds. " +
                 "Instance boot timeout: $instanceBootTimeout seconds.")
    $emuTestCfgDir = "$scriptLocation\config\emu_test"
    $logFile = Join-Path $adtEmuTestResultDir `
                         ($testSuiteName + ".log")

    $cmd = ("cmd /c " +
            "'python `"$adtInfraDir\emu_test\dotest.py`" " +
            "--file_pattern=`"$testFileName`" " +
            "--skip-adb-perf " +
            "--test_dir=$adtEmuTestResultDir " +
            "--session_dir=$adtEmuTestResultDir " +
            "--config_file=`"$emuTestCfgDir\test_cfg.csv`" " +
            "--buildername=`"localhost`" " +
            "--timeout=$($integrationTestSuiteTimeout * $softTimeoutRatio) " +
            "--subunit-file=$adtTestSubunitResults " +
            "--boot_time=$instanceBootTimeout >> $logFile 2>&1'")
            # --avd_list $testAvdName
    log_message "Executing $cmd"
    iex_with_timeout $cmd $testTimeout
}

function run_adt_emu_tests() {
    log_message 'Running emulator integration tests from adt_infra.'

    if ($adtEmuEnabledTests) {
        $enabledTests = $adtEmuEnabledTests.Split(",")
    }
    else {
        $enabledTests = $defaultAdtEmuEnabledTests
    }

    foreach ($testFileName in $enabledTests) {
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

    generate_subunit_report $adtTestSubunitResults $testResultsDir `
                            "integration_test_results"
}


ensure_dir_exists $unitTestResultsDir
ensure_dir_exists $isolatedUnitTestResultsDir
ensure_dir_exists $adtEmuTestResultDir

extract_unit_tests
prepare_adt_emu_tests
prepare_lib_paths

clear_test_stats

run_unit_tests
run_adt_emu_tests

validate_test_run
