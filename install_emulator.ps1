$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\config.ps1"
. "$scriptLocation\utils.ps1"

set_env "ANDROID_SDK_ROOT" $androidRootDir
set_env "ANDROID_EMULATOR_HOME" $androidEmulatorHome
