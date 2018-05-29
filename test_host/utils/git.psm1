$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

. "$scriptLocation\common.ps1"

function git_clone_pull($path, $url, $ref="master", $shallow=$false)
{
    log_message "Cloning / pulling: $url, branch: $ref"

    pushd .
    try  
    {
        if (!(Test-Path -path $path))
        {
            if ($shallow) {
                git clone $url $path --depth=1
            }
            else {
                git clone $url $path
            }

            if ($LastExitCode) { throw "git clone failed" }

            cd $path
        }
        else
        {
            cd $path

            git remote set-url origin $url
            if ($LastExitCode) { throw "git remote set-url failed" }

            git reset --hard
            if ($LastExitCode) { throw "git reset failed" }

            git clean -f -d
            if ($LastExitCode) { throw "git clean failed" }

            git fetch
            if ($LastExitCode) { throw "git fetch failed" }
        }

        git checkout $ref
        if ($LastExitCode) { throw "git checkout failed" }

        if ((git tag) -contains $ref) {
            log_message "Got tag $ref instead of a branch."
            log_message "Skipping doing a pull."
        }
        elseif ($(git log -1 --pretty=format:"%H").StartsWith($ref)){
            log_message "Got a commit id instead of a branch."
            log_message "Skipping doing a pull."
        }
        else {
            git pull
            if ($LastExitCode) { throw "git pull failed" }
        }
    }
    finally
    {
        popd
    }
}