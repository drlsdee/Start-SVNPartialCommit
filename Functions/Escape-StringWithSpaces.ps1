function Escape-StringWithSpaces {
    [Alias('espace')]
    [CmdletBinding()]
    param (
        # Input string
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [Alias('is')]
        [string]
        $InputString
    )
    if (($InputString -match '\s+') -and ($InputString -notmatch '^\"[\w+\W+\s+]+\"') ) {
        [string]$OutputString = "`"$InputString`""
    } else {
        [string]$OutputString = $InputString
    }
    return $OutputString
}
