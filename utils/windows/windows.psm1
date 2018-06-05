$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

. "$scriptLocation\common.ps1"

function _set_env($key, $val, $target="User") {
    $acceptableTargetList = @("process", "user", "machine")
    if ($target.ToLower() -notin $acceptableTargetList) {
        throw ("Cannot set environment variable `"$key`" to `"$val`". " +
               "Unsupported target: `"$target`".")
    }

    $varTarget = [System.EnvironmentVariableTarget]::$target

    [System.Environment]::SetEnvironmentVariable($key, $val, $varTarget)
}

function set_env($key, $val, $target="User") {
    log_message ("Setting environment value: `"$key`" = `"$val`". " +
                 "Target: `"$target`".")
    _set_env $key $val $target
    # You'll always want to set the "Process" target as well, so that
    # it applies to the current process. Just to avoid some weird issues,
    # we're setting it here.
    _set_env $key $val "Process"
}

function env_path_contains($path) {
    $normPath = $path.Replace("\", "\\").Trim("\")
    $env:Path -imatch "(?:^|;)$normPath\\?(?:$|;)"
}

function add_to_env_path($path, $target="User"){
    if (!(env_path_contains $path)) {
        log_message "Adding `"$path`" to %PATH%."
        set_env "PATH" "$env:Path;$path" $target
    }
    else {
        log_message "%PATH% already contains `"$path`"."
    }
}

function check_elevated() {
    log_message "Checking elevated permissions."

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = new-object System.Security.Principal.WindowsPrincipal(
        $identity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $elevated = $principal.IsInRole($adminRole)
    if (!$elevated) {
        throw "This script requires elevated privileges."
    }
}

function stop_processes($name) {
    log_message "Stopping process(es): `"$name`"."
    get-process $name |  stop-process -PassThru | `
        % { log_message "Stopped process: `"$($_.Name)`"." }
}

function check_windows_feature($featureName) {
    log_message("Ensuring that the following Windows feature is available: " +
                "`"$featureName`".")

    $feature = Get-WindowsOptionalFeature -FeatureName "$featureName" -Online
    if (!($feature)) {
        throw "Could not find Windows feature: `"$featureName`"."
    }
    if ($feature.Count -gt 1) {
        # We're going to allow wildcards.
        log_message ("WARNING: Found multiple features matching " +
                     "the specified name: $($feature.FeatureName). " +
                     "Will ensure that all of them are enabled.")
        log_message $msg
    }

    $feature | `
        ? { $_.State -eq "Enabled" } | `
        % { log_message ("The following Windows feature is available: " +
                         "`"$($_.FeatureName)`".")}
    $disabledFeatures = @()
    $feature | `
        ? { $_.State -ne "Enabled" } | `
        % { $disabledFeatures += $_.FeatureName }

    if ($disabledFeatures) {
        throw "The following Windows features are not enabled: $missingFeatures."
    }
}

function enable_rdp_access() {
    log_message "Enabling RDP access."

    Set-ItemProperty `
        -Path "HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server" `
        -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}
