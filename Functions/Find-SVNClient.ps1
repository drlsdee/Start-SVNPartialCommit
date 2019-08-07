function Find-SVNClient {
    [CmdletBinding()]
    [array]$allPaths = ($env:Path -split ';').Where({$_})
    [array]$svnPaths = @()
    $allPaths.ForEach({
        $svnTestPath = Join-Path -Path $_ -ChildPath 'svn.exe'
        if (Test-Path -Path $svnTestPath -PathType Leaf) {
            $svnPaths += $svnTestPath
        }
    })
    if ($svnPaths.Count) {
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Found $($svnPaths.Count) versions of SVN client."
        [string]$resultPath = $svnPaths[0] | Resolve-Path
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Using path: `"$resultPath`""
        return $resultPath
    } else {
        Write-Error -Category ObjectNotFound -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: SVN client not found! Exiting..."
        exit
    }
}
