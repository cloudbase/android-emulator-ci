$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

# Sourcing the config to set some default values.
# This should be avoided as much as possible.
# TODO: drop this.
. "$scriptLocation\..\..\test_host\config\global_config.ps1"

function log_message($message) {
    echo "[$(Get-Date)] $message"
}

function iex_with_timeout() {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$cmd,
        [Parameter(Mandatory=$true)]
        [int]$timeoutSec
    )

    $job = start-job -ArgumentList $cmd -ScriptBlock {
        param($c)
        iex $c
        if ($LASTEXITCODE) {
            throw "Command returned non-zero code($LASTEXITCODE): `"$c`"."
        }
    }

    try {
        wait-job $job -timeout $timeoutSec

        if ($job.State -notin @("Completed", "Failed")) {
            throw "Command timed out ($($timeoutSec)s): `"$cmd`"."
        }
        receive-job $job
    }
    finally {
        stop-job $job
        remove-job $job
    }
}
