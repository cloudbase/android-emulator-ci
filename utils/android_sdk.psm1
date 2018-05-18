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
    # We need to accept sdk licenses before
    # installing android sdk packages.
    $answers = "y`n"
    # Probably we won't be asked more than 50 times.
    # Would've been nice if the sdk manager had an argument
    # to bypass this, though.
    1..50 | % { $answers+="y`n"}
    $answers | & $sdkManager --licenses
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
