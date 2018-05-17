$androidRootDir = "C:\Android"
$androidSdkRoot = "$androidRootDir\sdk"
$androidEmulatorHome = "$androidRootDir\android_home"
$androidAvdDir = "$androidEmulatorHome\avd"
$androidEmulatorDir = "$androidSdkRoot\emulator"

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

# For now, we'll just hardcode it. Make msys is installed
# at this location.
$msysBinDir = join-path $env:HOMEDRIVE "msys\1.0\bin"
$env:PATH ="$msysBinDir;$($env:PATH)"
