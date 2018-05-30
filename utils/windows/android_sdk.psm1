$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

. "$scriptLocation\common.ps1"

function install_android_sdk_package($packageName) {
    # We may consider installing multiple packages at once.
    # This command requires confirmation (unfortunately, there's no
    # argument that allows bypassing this)
    log_message "Installing Android SDK package: `"$packageName`""
    & $sdkManager "$packageName"
}

function accept_sdk_licenses() {
    log_message "Accepting Android SDK licenses."
    # We need to accept sdk licenses before
    # installing android sdk packages.
    $answers = "y`n"
    # Probably we won't be asked more than 50 times.
    # Would've been nice if the sdk manager had an argument
    # to bypass this, though.
    1..50 | % { $answers+="y`n"}
    ( $answers | & $sdkManager --licenses ) | out-null
}

function create_avd($avdName, $packageName, $avdDevice, $abi, $path) {
    if (!$path) {
        $path = join-path $AndroidAvdDir $avdName
    }

    log_message ("Creating avd: $avdName - $packageName - " +
                 "$avdDevice - $abi - $path")
    & $avdManager create avd `
        --name $avdName `
        --package $packageName `
        --device $avdDevice `
        --abi $abi `
        --path $path
}

function set_android_emulator_feature($featureName, $status) {
    log_message ("Setting Android emulator feature `"$featureName`" to " +
                 "`"$status`".")
    if ($status -notin @("on", "off")) {
        throw ("Cannot set emulator feature. " +
               "Invalid status: $status. Expecting on/off.")
    }

    if (!(test-path $androidUserAdvancedFeatures)) {
        $content = "$featureName = $status`r`n"
    }
    else {
        $content = gc $androidUserAdvancedFeatures
        if ($content -match "^[ `t]*$featureName") {
            $content = $content -replace `
                '($featureName =).*',"`$1 $status"
        }
        else {
            $content += "`r`n$featureName = $status`r`n"
        }
    }

    sc $androidUserAdvancedFeatures $content
}
