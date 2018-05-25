$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

. "$scriptLocation\common.ps1"

function get_full_path($path) {
    # Unlike Resolve-Path, this doesn't throw an exception if the path does not exist.
    return (
        $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            $path)
    )
}

function check_path($path) {
    if (!(test-path $path)) {
        throw "Could not find path: `"$path`"."
    }
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
    log_message ("Ensuring symlink exists: $link -> $target. " +
                 "Directory: $isDir")

    $target = get_full_path $target
    $link = get_full_path $link

    if ($target -eq $link) {
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

function ensure_binary_available($bin) {
    if (!(where.exe $bin)) {
        throw ("Could not find `"$bin`". Make sure that it's installed and its " +
               "path is included in PATH.")
    }
}

function ensure_dir_exists($path) {
    if (!(test-path $path)) {
        mkdir $path | out-null
    }
}

function ensure_dir_empty($path) {
    # Ensure that the specified dir exists and is empty.
    if (test-path $path) {
        log_message "Directory already exists. Cleaning it up: `"$path`"."
        rm -recurse -force $path
    }
    mkdir $path | out-null
}

function check_remove_dir($path) {
    # Ensure that the specified dir exists and is empty.
    if (test-path $path) {
        log_message "Removing dir: `"$path`"."
        rm -recurse -force $path
    }
}

function extract_zip($src, $dest) {
    # Make sure to use full paths.
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    log_message "Extracting zip: `"$src`" -> `"$dest`"."
    [System.IO.Compression.ZipFile]::ExtractToDirectory($src, $dest)
}
