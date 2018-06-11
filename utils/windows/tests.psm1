$scriptLocation = [System.IO.Path]::GetDirectoryName(
    $myInvocation.MyCommand.Definition)

. "$scriptLocation\common.ps1"

function run_gtest($binPath, $resultDir, $timeout=-1, $testFilter) {
    log_message "Running tests: $binPath"

    $binName = (split-path -leaf $binPath) -replace ".exe$",""
    $xmlOutputPath = join-path $resultDir ($binName + "_results.xml")
    $consoleOutputPath = join-path $resultDir ($binName + "_results.log")
    $gtestFilterArg = ""

    if ($testFilter) {
        $gtestFilterArg = "--gtest_filter=`"$testFilter`""
    }

    $cmd = ("cmd /c '$binPath --gtest_output=xml:$xmlOutputPath $gtestFilterArg " +
            "> $consoleOutputPath 2>&1'")
    iex_with_timeout $cmd $timeout  
}
