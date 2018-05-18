$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\..\config.ps1"

function log_message($message) {
    echo "[$(Get-Date)] $message"
}
