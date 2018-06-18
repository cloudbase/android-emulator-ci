# We need to run sysprep each time we update the Windows image.

$cbsInitDir = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init"
$cbsInitLogDir = "$cbsInitDir\log"
$unattendFile = "$cbsInitDir\conf\Unattend.xml"

function clear_eventlog ()
{
    $Logs = Get-EventLog -List | ForEach {$_.Log}
    $Logs | % {Clear-EventLog -Log $_ }
    Get-EventLog -List
}

rm -Recurse -Force "$cbsInitLogDir\*"
clear_eventlog
ipconfig /release

C:\Windows\System32\Sysprep\sysprep.exe `
    /generalize /oobe /shutdown `
    /unattend:$unattendFile
