# Useful for debugging purposes.

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
import-module "$scriptLocation\..\utils\windows\all.psm1"

check_elevated
enable_rdp_access
