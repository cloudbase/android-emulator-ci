function log_message($message) {
    echo "[$(Get-Date)] $message"
}

function _set_env($key, $val, $target="User") {
    $acceptableTargetList = @("process", "user", "machine")
    if ($target.ToLower() -notin $acceptableTargetList) {
        $err = "Cannot set environment variable `"$key`" to `"$val`". " + 
               "Unsupported target: `"$target`"."
        throw $err
    }

    $varTarget = [System.EnvironmentVariableTarget]::$target

    [System.Environment]::SetEnvironmentVariable($key, $val, $varTarget)
}

function set_env($key, $val, $target="User") {
	_set_env $key $val $target
	# You'll always want to set the "Process" target as well, so that
	# it applies to the current process. Just to avoid some weird issues,
	# we're setting it here.
	_set_env $key $val "Process"
}
