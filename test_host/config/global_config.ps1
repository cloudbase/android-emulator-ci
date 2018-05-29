$androidRootDir = "C:\Android"
$androidSdkRoot = "$androidRootDir\sdk"
$androidEmulatorHome = "$androidRootDir\android_home"
$androidAvdDir = "$androidEmulatorHome\avd"
$androidEmulatorDir = "$androidSdkRoot\emulator"
$androidUserAdvancedFeatures = "$androidEmulatorHome\advancedFeatures.ini"
$androidPlatformToolsDir = "$androidSdkRoot\platform-tools"
$androidSdkToolsBinDir = "$androidRootDir\sdk\bin"

$logDir = "$androidRootDir\log"
$testResultsDir = "$logDir\results"
$unitTestResultsDir = "$testResultsDir\unittests"
# We're going to use a single file providing info about failed tests.
$failedTestListFile = "$testResultsDir\failed_tests.txt"
$executedTestListFile = "$testResultsDir\executed_tests.txt"
# Can't find a better name for those tests at the moment.
$adtEmuTestResultDir = "$testResultsDir\adt_infra_emu_tests"
$adtEmuTestLog = "$adtEmuTestResultDir\console.log"
$adtEmuEnabledTests = @("test_boot.py", "test_console.py", "test_ui.py")

# Not sure yet if it's safe to use a separate dir.
$emulatorUnitTestsDir = "$androidEmulatorDir\unittests"

# We'll use this dir for temporary files, simplifying cleanups.
# Since this will also be used for storing the images, we assume
# it will also have enough space for our needs.
$androidTempDir = "$androidRootDir\tmp"

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
$msysBinDir = join-path $env:HOMEDRIVE "msys\1.0\bin"

# The timeout to use per unit test suite.
# 5 minutes seem reasonable for now.
# Unfortunately, this option doesn't seem to be used properly by the
# emulator integration tests, using the global "--timeout" value
# as boot timeout.
$unitTestSuiteTimeout = 300
# 30 min should be enough for integration test suites (omitting CTS for now).
$integrationTestSuiteTimeout = 1500
$instanceBootTimeout = 600
# The ratio between soft timeout and hard timeout. We're using soft timeouts
# for the tests, giving them time to clean up and publish results, before
# brutally killing them.
$softTimeoutRatio = 0.90

$adtInfraRepoUrl = 'https://android.googlesource.com/platform/external/adt-infra'
$adtInfraBranch = "emu-master-dev"
$adtInfraDir = "$androidRootDir\adt-infra"

# We spare some time/space by using shallow clones. When debugging,
# full clones may be desired.
$shallowGitClones = $true