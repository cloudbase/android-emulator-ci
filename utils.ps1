$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"

function log_message($message) {
    echo "[$(Get-Date)] $message"
}

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
    log_message "Setting environment value: `"$key`" = `"$val`". " +
                "Target: `"$target`"."
	_set_env $key $val $target
	# You'll always want to set the "Process" target as well, so that
	# it applies to the current process. Just to avoid some weird issues,
	# we're setting it here.
	_set_env $key $val "Process"
}

function get_full_path($path) {
    # Unlike Resolve-Path, this doesn't throw an exception if the path does not exist.
    return (
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            $path)
    )
}

function install_android_sdk_package($packageName) {
    # We may consider installing multiple packages at once.
    # This command requires confirmation (unfortunately, there's no
    # argument that allows bypassing this)
    log_message "Installing Android SDK package: `"$packageName`""
    echo "y" | & $sdkManager "$packageName"
}

function create_avd($avdName, $packageName, $avdDevice, $abi, $path) {
    if (!$path) {
        $path = join-path $AndroidAvdDir $avdName
    }

    log_message "Creating avd: $avdName - $packageName - " +
                "$avdDevice - $abi - $path"
    & $avdManager create avd `
        --name $avdName `
        --package $packageName `
        --device $avdDevice `
        --abi $abi `
        --path $path
}

function check_elevated() {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = new-object System.Security.Principal.WindowsPrincipal(
        $identity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $elevated = $principal.IsInRole($adminRole)
    return $elevated
}

function get_link_target($linkPath) {
    $linkPath = Resolve-Path $linkPath
    $basePath = Split-Path $linkPath
    $link = Split-Path -leaf $linkPath
    $dir = cmd /c dir /a:l $basePath | findstr /C:"$link"
    $regx = $link + '\ *\[(.*?)\]'

    $Matches = $null
    $found = $dir -match $regx
    if ($found) {
        if ($Matches[1]) {
            # We'll try to resolve relative paths.
            pushd $basePath
            $target = get_full_path $Matches[1]
            popd
            return $target
        }
    }
    return ''
}

function delete_symlink($link) {
    log_message "Deleting link `"$link`"."
    fsutil reparsepoint delete $link
    remove-item $link -Force -Confirm:$false
}

function ensure_symlink($target, $link, $isDir) {
    log_message "Ensuring symlink exists: $link -> $target. " +
                "Directory: $isDir"

    if ((get_full_path $target) -eq (get_full_path $link)) {
        log_message "$target IS $link. Skipping creating a symlink."
    }

    $shouldCreate = $false
    if (test-path $link) {
        $existing_target = get_link_target $link
        if (!($existing_target)) {
            throw ("Cannot create symlink. $link already exists " +
                   "but is not a symlink")
        }

        if ($existing_target -ne $target) {
            log_message "Recreating symlink. Current target: $existing_target"
            delete_symlink $link
            $shouldCreate = $true
        }
    }
    else {
        $shouldCreate = $true
    }

    if ($shouldCreate) {
        $dirArg = ""
        if ($isDir) {
            $dirArg = "/D"
        }

        log_message "cmd /c mklink $dirArg $link $target"
        iex "cmd /c mklink $dirArg $link $target"
        if ($LASTEXITCODE) {
            throw "Failed to create symlink."
        }
    }
}

function stop_processes($name) {
    log_message "Stopping process(es) `"$name`"."
    get-process $name |  stop-process -PassThru | `
        % { log_message "Stopped process: `"$($_.Name)`"." }
}

function check_path($path) {
    if (!(test-path $path)) {
        throw "Could not find path: `"$path`"."
    }
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
