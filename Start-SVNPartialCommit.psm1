# Import functions:
[array]$FunctionsToImport = Get-ChildItem -Path "$PSScriptRoot\Functions" -File -Filter '*.ps1' | Resolve-Path -Relative
$FunctionsToImport.ForEach({
    . $_
})

<#
.SYNOPSIS
    The module allows to split a bunch of changed files in your copy of SVN repository to several commits with defined max count of items in each. The total number of changed items splits into separate SVN changelists.
.DESCRIPTION
    The module allows to split a bunch of changed files in your copy of SVN repository to several commits with defined max count of items in each. The total number of changed items splits into separate SVN changelists.
    GitHub: https://github.com/drlsdee/Start-SVNPartialCommit
.PARAMETER Repository
If the module starts in the SVN working folder, it is assumed that the current folder is exactly the copy of the target SVN repository for which you want to commit your changes. Otherwise, you should explicitly specify the path to the SVN repository.
.PARAMETER SvnExe
Full path to the SVN client executable file. By default the module searches the executable in all paths included into your '$env:PATH' variable.
.PARAMETER CommitMessage
Exactly what is written on the package. If your commit splits into a several commits, numbers from '0' will be added to the end of each message.
.PARAMETER Count
Maximum count of changed items per single commit. If the parameter is not set or if the count of changed items is less or equal of number specified, all items will be committed by one transaction.
.PARAMETER Encoding
The parameter specifies the encoding for reading the output of the 'svn status' command. It suddenly becomes important if some of the paths in your repository contain characters of national alphabets (e.g. cyrillic). The default value is 'UTF8'. And if you run 'svn status --xml', you can see that the <XML declaration> in output also points to UTF8 encoding. At least today, right now.
.PARAMETER AutoAdd
If parameter 'AutoAdd' is set, new unversioned items will be added under version control.
.PARAMETER RemoveMissing
If parameter 'RemoveMissing' is set, missing items (e.g. removed from your working folder with external command, not 'svn delete') will be deleted from version control!
.PARAMETER SvnStatesValid
List of SVN states for changed items. The list loads from JSON file 'SVNStates.json' in module's subfolder 'Data'. Now contains 'deleted', 'added', 'modified' and 'replaced' states. You may override that.
.PARAMETER SvnStatesInValid
List of SVN states for problem items. The list loads from JSON file 'SVNStates.json' in module's subfolder 'Data'. Now contains only 'missing' state. You may override that.
.EXAMPLE
    PS C:\> Start-SVNPartialCommit -CommitMessage 'test commit' -Count 10
    The function runs in current location, finds changed items (if any) and commits them into SVN repository. If total count of changed items is more than 10, the function will split them into several commits. If total count is less or equal than 10, there will be a single commit. New unversioned items and missing items stays untouched.
.EXAMPLE
    PS C:\> Start-SVNPartialCommit -CommitMessage 'test commit' -Count 10 -AutoAdd
    In general the same behavior as in the example 1 above, but new items will be added into version control system. Missing items are still untouched.
.EXAMPLE
    PS C:\> Start-SVNPartialCommit -CommitMessage 'test commit' -Count 10 -AutoAdd -RemoveMissing
    In general the same behavior as in the examples 1 and 2 above, but new items will be added into version control system and missing items will be removed from it.
.EXAMPLE
    PS C:\> Start-SVNPartialCommit -Repository '.\TestRepo'
    The function is launched in the working folder specified in the 'Repository' parameter. All other options are by default. A commit message is not specified, so it will be generated from the user name, computer name, and domain name. The maximum number of items per commit is also not defined, so all items will be committed in one transaction. New and changed files will not be processed.
.INPUTS
    [System.String]
    [System.Int32]
    [System.Array]
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
.NOTES
    General notes
#>
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

        # Valid SVN states for changed items (loaded from JSON file in the module subfolder, you may override that).
        [Parameter(DontShow=$true)]
        [array]
        $SvnStatesValid,

        # SVN states for problem items, e.g. missing (loaded from JSON file in the module subfolder, you may override that).
        [Parameter(DontShow=$true)]
        [array]
        $SvnStatesInValid
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

        if (-not $SvnStatesValid) {
            $SvnStatesValid = (Get-Content -Path "$PSScriptRoot\Data\SVNStates.json" | ConvertFrom-Json).SvnStatesValid
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Valid SVN states loaded from file:"
            $SvnStatesValid.ForEach({
                Write-Verbose -Message "`"$_`""
            })
        }

        if (-not $SvnStatesInValid) {
            $SvnStatesInValid = (Get-Content -Path "$PSScriptRoot\Data\SVNStates.json" | ConvertFrom-Json).SvnStatesInValid
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Valid SVN states loaded from file:"
            $SvnStatesInValid.ForEach({
                Write-Verbose -Message "`"$_`""
            })
        }
    }
    
    process {
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Creating an object for SVN executable..."
        $svnObject = Set-ConsoleAppStartupParameters -FullPath $SvnExe -WorkingDirectory $Repository -OutEncoding $Encoding

        # Getting initial status of repository:
        $svnRawStatus = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments 'status -v --xml' -SkipEmpty -OutputType Both
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
                    $outputMissing = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $deleteString -OutputType StandardError -SkipEmpty
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
                    $outputNew = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $addString -OutputType StandardError -SkipEmpty
                })
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Renew status..."

                # Get status again:
                $svnRawStatus = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments 'status -v --xml' -SkipEmpty -OutputType Both
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
            $outputCommit = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $commitString -OutputType StandardError -SkipEmpty
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
                    $outputAddToCL = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $ChangeListCommandAdd -OutputType StandardError -SkipEmpty
                })
            }
            $ChangeListArray.ForEach({
                $commitString = New-SVNCommitString -ChangeList $_
                $outputCommit = Start-ConsoleAppRedirectOutput -processObject $svnObject -Arguments $commitString -OutputType StandardError -SkipEmpty
                Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Committing SVN changelist: $_..."
            })
        }
    }
    
    end {
        # Creating object for output:
        $OutValues = @{
            'ErrorsGetStatus' = $svnRawStatus.StandardError
            'ErrorsAddNew' = $outputNew.StandardError
            'ErrorsDeleteMissing' = $outputMissing.StandardError
            'ErrorsChangeList' = $outputAddToCL.StandardError
            'ErrorsCommit' = $outputCommit.StandardError
        }
        $OutObject = New-Object -TypeName psobject -Property $OutValues
        if ($OutObject.Properties.Where({$_.Value})) {
            Write-Warning -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Ended with some errors. See below:"
            $OutObject
        } else {
            Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Ended with no visible errors."
        }
        Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: End of function `"$($MyInvocation.MyCommand)`""
        return
    }
}

Export-ModuleMember -Function 'Start-SVNPartialCommit'