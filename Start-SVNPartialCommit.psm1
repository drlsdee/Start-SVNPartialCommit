# Import functions:
[array]$FunctionsToImport = Get-ChildItem -Path "$PSScriptRoot\Functions" -File -Filter '*.ps1' | Resolve-Path -Relative
$FunctionsToImport.ForEach({
    . $_
})

function Start-SVNPartialCommit {
    [CmdletBinding()]
    param (
        # Path to SVN repository. Default is current location.
        [Parameter()]
        [string]
        $Repository,

        # Full path to SVN executable.
        [Parameter(DontShow=$true)]
        [string]
        $SvnExe,

        # Commit message
        [Parameter()]
        [string]
        $CommitMessage,

        # Maximum count of items in single commit. Default is count of all changed items.
        [Parameter()]
        [int]
        $Count,

        # Encoding (Default is UTF8)
        [Parameter(DontShow=$true)]
        [ValidateSet('ASCII','BigEndianUnicode','Default','Unicode','UTF32','UTF7','UTF8')]
        [string]
        $Encoding,

        # If set, automatically adds all new items under version control.
        [Parameter()]
        [switch]
        $AutoAdd,

        # If set, removes missing items.
        [Parameter()]
        [switch]
        $RemoveMissing,

        # Valid SVN states for changed items (loaded from text file in the module subfolder, you may override that).
        [Parameter(DontShow=$true)]
        [array]
        $SvnStatesValid = (Get-Content -Path "$PSScriptRoot\Data\SVNStatesValid.txt"),

        # SVN states for problem items, e.g. missing (loaded from text file in the module subfolder, you may override that).
        [Parameter(DontShow=$true)]
        [array]
        $SvnStatesInValid = (Get-Content -Path "$PSScriptRoot\Data\SVNStatesInValid.txt")
    )
    
    begin {
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Starting function `"$($MyInvocation.MyCommand)`""
        # Set path to SVN client:
        if (-not $SvnExe) {
            $SvnExe = Find-SVNClient
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Using SVN executable file: `"$SvnExe`""
        }

        # Set encoding:
        if (-not $Encoding) {
            $Encoding = 'UTF8'
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Using default encoding for the module: 'UTF8'"
        }
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::$Encoding
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Using encoding: `"$Encoding`""

        # If the path to SVN repository is not set, using the current location:
        if (-not $Repository) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Path to SVN repository is not set. Using current location..."
            $Repository = (Get-Location).Path
        }
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Path to SVN repository is set to `"$Repository`""

        # Check if the folder is a valid repository:
        if (Get-ChildItem -Path $Repository -Directory -Hidden -Filter '.svn') {
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: It seems the folder is valid SVN repository. Continue..."
        } else {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: The folder is not a valid SVN repository! Exiting function `"$($MyInvocation.MyCommand)`""
            return
        }

        # Commit message (and name for changelist)
        if (-not $CommitMessage) {
            $CommitMessage = "Commit by $env:USERNAME from $env:COMPUTERNAME in $env:USERDNSDOMAIN"
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Commit message is not set. Generic message will be used..."
        }
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Commit message is `"$CommitMessage`""

        if (-not $Count) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Maximum items count for single commit is not set. All changed items will be committed..."
        } else {
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Maximum items count for single commit is $Count. If count of changed items is less then $Count, all items will be committed."
        }

        if ($AutoAdd) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: All new unversioned items will be added under version control and committed!"
        }
    }
    
    process {
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Creating an object for SVN executable..."
        $svnObject = Set-ConsoleAppStartupParameters -FullPath $SvnExe -WorkingDirectory $Repository -OutEncoding $Encoding

        # Getting initial status of repository:
        $svnRawStatus = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments 'status -v --xml' -SkipEmpty -OutputType StandardOutput
        $svnInitStatus = New-Object -TypeName System.Xml.XmlDocument
        $svnInitStatus.LoadXml($svnRawStatus.StandardOutput)

        # Check for missing items:
        $itemsMissing = $svnInitStatus.status.target.entry.Where({
            $_.'wc-status'.item -in $SvnStatesInValid
        })
        if ($itemsMissing) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Found $($itemsMissing.Count) MISSING or CONFLICTED item(s)"
            if ($RemoveMissing) {
                $itemsMissing.ForEach({
                    $itemPath = Escape-StringWithSpaces -InputString $_.path
                    Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Item `"$itemPath`" will be DELETED!"
                    $deleteString = "delete $itemPath --force"
                    Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $deleteString -OutputType StandardError -SkipEmpty
                })
            } else {
                # Do nothing
                Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: You have selected do nothing, so all the missing items will be skipped now. You should resolve the problem manually."
            }
        }

        # Check for new unversioned items:
        $itemsNew = $svnInitStatus.status.target.entry.Where({
            $_.'wc-status'.item -eq 'unversioned'
        })
        if ($itemsNew.Count) {
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: $($itemsNew.Count) new item(s) found!"
            if ($AutoAdd) {
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Adding..."

                # Add new items under version control:
                $itemsNew.ForEach({
                    $itemPath = Escape-StringWithSpaces -InputString $_.path
                    $addString = "add $itemPath --force"
                    Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Adding $itemPath..."
                    Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $addString -OutputType StandardError -SkipEmpty
                })
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Renew status..."

                # Get status again:
                $svnRawStatus = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments 'status -v --xml' -SkipEmpty -OutputType StandardOutput
                $svnInitStatus.LoadXml($svnRawStatus.StandardOutput)
            } else {
                # Do nothing
                Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: New items will be skipped. You may run command `'svn add <path-to-item>`' to add new items manually."
            }
        }

        # Check for new items under version control:
        $itemsChanged = $svnInitStatus.status.target.entry.Where({
            $_.'wc-status'.item -in $SvnStatesValid
        })
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Found $($itemsChanged.Count) changed item(s)"

        # Commit:
        # No changes
        if ($itemsChanged.Count -eq 0) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: There are no changed items found. Exiting..."
            return
        # Commit all items:
        } elseif ((-not $Count) -or ($itemsChanged.Count -le $Count)) {
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Count of changed items is less or equal to max items count for single commit, or max count is not set."
            $itemsChanged.ForEach({
                $itemPath = Escape-StringWithSpaces -InputString $_.path
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Item `"$itemPath`" will be committed..."
            })
            $commitString = New-SVNCommitString -CommitMessage $CommitMessage
            Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $commitString -OutputType StandardError -SkipEmpty
        # Commit partially:
        } else {
            $commitCount = [System.Math]::Ceiling($itemsChanged.Count / $Count)
            [array]$ChangeListArray = @()
            for ($commitNumber = 0; $commitNumber -lt $commitCount; $commitNumber++) {
                $ChangeListName = Escape-StringWithSpaces -InputString "$CommitMessage #$commitNumber"
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Created SVN changelist: $ChangeListName."
                $ChangeListArray += $ChangeListName
                $ChangeListCommandPrefix = "changelist $ChangeListName"
                $indexStart = $commitNumber * $Count
                $indexEnd = $indexStart + $Count - 1
                $itemsChanged[$indexStart..$indexEnd].ForEach({
                    $itemPath = Escape-StringWithSpaces -InputString $_.path
                    Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Item $itemPath added to SVN changelist: $ChangeListName."
                    $ChangeListCommandAdd = $ChangeListCommandPrefix, $itemPath -join ' '
                    Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $ChangeListCommandAdd -OutputType StandardError -SkipEmpty
                })
            }
            $ChangeListArray.ForEach({
                $commitString = New-SVNCommitString -ChangeList $_
                Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $commitString -OutputType StandardError -SkipEmpty
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Committing SVN changelist: $_..."
            })
        }
    }
    
    end {
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: End of function `"$($MyInvocation.MyCommand)`""
    }
}

Export-ModuleMember -Function 'Start-SVNPartialCommit'