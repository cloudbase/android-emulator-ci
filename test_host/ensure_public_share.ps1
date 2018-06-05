# This will allow easily exposing the logs and test results.

Param(
    [Parameter(Mandatory=$true)]
    [string]$shareName,
    [Parameter(Mandatory=$true)]
    [string]$sharePath,
    [string]$accessRight="Full"
)

$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
import-module "$scriptLocation\..\utils\windows\all.psm1"

check_elevated

log_message "Enabling 445 (SMB) port."
netsh advfirewall firewall add rule `
    name="SMB access" dir=in action=allow protocol=TCP `
    localport=445

ensure_smb_share $shareName $sharePath
grant_smb_share_access $shareName "Everyone" $accessRight

$anonymousLogonSid = "*S-1-5-7"
grant_smb_share_access $shareName $anonymousLogonSid $accessRight
