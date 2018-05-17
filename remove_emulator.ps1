$ErrorActionPreference = "Stop"

$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

function stop_emulator() {
    log_message "Stopping emulator instances."
    stop_processes "emulator*"
    stop_processes "qemu*"
    stop_processes "adb*"
    stop_processes "sdkmanager*"
    stop_processes "avdmanager*"
}

function cleanup_files() {
    log_message "Removing emulator files: `"$androidRootDir`"."
    # For now, we'll delete the Android root dir completely,
    # assuming that all the related files reside there.
    check_remove_dir $androidRootDir
    if (test-path $androidEmulatorHome) {
        $linkTarget = get_link_target $androidEmulatorHome
        if ($linkTarget) {
            log_message "Deleting symlink $androidEmulatorHome <-> $linkTarget"
            delete_symlink $androidEmulatorHome
        }
    }
}

stop_emulator
cleanup_files

log_message "Cleaned up emulator."
