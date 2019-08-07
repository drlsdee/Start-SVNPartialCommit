<#
.SYNOPSIS
    A simple and stupid function for timestamp with milliseconds
.DESCRIPTION
    A simple and stupid function for timestamp with milliseconds.
.EXAMPLE
    PS C:\> New-Timestamp
    Creates a string like this: '[2019-07-30 03:48:16:027]:'
.EXAMPLE
    PS C:\> Write-Verbose -Message "$(New-TimeStamp) [$($MyInvocation.MyCommand)]: Starting function `"$($MyInvocation.MyCommand)`""
    Creates a verbose message with timestamp and function name: 'VERBOSE: [2019-07-30 03:48:16:027]: Starting function "Do-SomeThing"'
.INPUTS
    None
.OUTPUTS
    [System.String]
.NOTES
    None
#>
function New-TimeStamp {
    $dateToString = (Get-Date -Format "yyyy-MM-dd hh:mm:ss:fff").ToString()
    $TimeStamp = "[$dateToString]:"
    return $TimeStamp
}