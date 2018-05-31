$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config\global_config.ps1"

import-module "$scriptLocation\..\utils\windows\all.psm1"

check_windows_feature "HypervisorPlatform"
$javaHome = $env:JAVA_HOME
if (!($javaHome)) {
    throw "JAVA_HOME is not set. Please install JRE/JDK 8."
}

check_path $env:JAVA_HOME
check_path $msysBinDir

# Test requirements
ensure_binary_available "python"
ensure_binary_available "pip"
