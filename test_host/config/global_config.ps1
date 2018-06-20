$androidRootDir = "C:\Android"
$androidSdkRoot = "$androidRootDir\sdk"
$androidEmulatorHome = "$androidRootDir\android_home"
$androidAvdDir = "$androidEmulatorHome\avd"
$androidEmulatorDir = "$androidSdkRoot\emulator"
$androidUserAdvancedFeatures = "$androidEmulatorHome\advancedFeatures.ini"
$androidPlatformToolsDir = "$androidSdkRoot\platform-tools"
$androidEmulatorBinDir = "$androidEmulatorDir\bin"

# $logDir = "$androidRootDir\log"

$testResultsDir = "$androidRootDir\test_results"
$testResultDetailsDir = "$testResultsDir\details"
$unitTestResultsDir = "$testResultDetailsDir\unit_tests"
$isolatedUnitTestResultsDir = "$unitTestResultsDir\isolated"
$functionalTestResultDir = "$testResultDetailsDir\functional_tests"
$defaultEnabledFunctionalTests = @("test_boot", "test_console", "test_ui")
# UI tests seem to take quite a while.
$customTestTimeout=@{"test_ui"=10800;
                     "test_console"=1800}
# Those tests are known to crash (possibly testing features that are
# unsupported on Windows), we'll isolate them for now.
$isolatedUnitTests=@{
    "android_emu(64)?_unittests.exe"=`
        @("RamSaverTest.*", "RamSnapshotTest.*");
    "android_emu_unittests.exe"=`
        @("RamLoaderTest.Simple");
    "android_emu64_unittests.exe"=`
        @("LazyInstance.MultipleThreads", "OnDemandTest.multiConstruct")}

$unitTestSubunitResults = "$unitTestResultsDir\unit_tests_subunit"
$functionalSubunitResults = `
    "$functionalTestResultDir\functional_tests_subunit"

# Not sure yet if it's safe to use a separate dir.
$emulatorUnitTestsDir = "$androidEmulatorDir\unittests"

# We'll use this dir for temporary files, simplifying cleanups.
# Since this will also be used for storing the images, we assume
# it will also have enough space for our needs.
$androidTempDir = "$androidRootDir\tmp"

$gradleHomeDir="~\.gradle"
$gradleInitFile="$gradleHomeDir\init.gradle"

$androidDefaultHomeDir = "~\.android"
$androidDefaultAvdDir = "$androidDefaultHomeDir\avd"

$sdkTools = "$androidSdkRoot\tools\bin"
$sdkManager = "$sdkTools\sdkmanager.bat"
$avdManager = "$sdkTools\avdmanager.bat"

# We'll have a default AVD that may be used for test purposes.
$testAvdName = "Test_Nexus_5X_x86"
$testAvdPackage = "system-images;android-26;google_apis;x86"
$testAvdDevice = "Nexus 5X"
$testAvdAbi = "google_apis/x86"

# For now, we'll just hardcode it. Make sure msys is installed
# at this location.
$msysBinDir = "C:\msys\1.0\bin"

# The timeout to use per unit test suite.
# 5 minutes seem reasonable for now.
# Unfortunately, this option doesn't seem to be used properly by the
# emulator functional tests, using the global "--timeout" value
# as boot timeout.
$unitTestSuiteTimeout = 300
# 60 min should be enough for functional test suites (omitting CTS for now).
$functionalTestSuiteTimeout = 1500
$instanceBootTimeout = 600
# The ratio between soft timeout and hard timeout. We're using soft timeouts
# for the tests, giving them time to clean up and publish results, before
# brutally killing them.
$softTimeoutRatio = 0.90

# $adtInfraRepoUrl = 'https://android.googlesource.com/platform/external/adt-infra'
# Using a fork until some fixes are merged upstream.
$adtInfraRepoUrl = 'https://github.com/petrutlucian94/adt-infra'
$adtInfraBranch = "emu-master-dev"
$adtInfraDir = "$androidRootDir\adt-infra"

# We spare some time/space by using shallow clones. When debugging,
# full clones may be desired.
$shallowGitClones = $true
