function New-SVNCommitString {
    # svn commit --changelist CnahgeListName -m "Commit Message #111"
    [CmdletBinding()]
    param (
        # SVN changelist name
        [Parameter(Mandatory=$true,
        ParameterSetName='ChangeList')]
        [string]
        $ChangeList,

        # Commit message
        [Parameter(Mandatory=$true,
        ParameterSetName='SingleCommit')]
        [string]
        $CommitMessage,

        # Partial commit number
        [Parameter(ParameterSetName='SingleCommit')]
        [int]
        $CommitNumber = 0
    )

    if ($ChangeList) {
        $ChangeList = Escape-StringWithSpaces -InputString $ChangeList
        $CommitMessage = $ChangeList
        $svnCommand = "commit --changelist $ChangeList -m"
    } else {
        $CommitMessage = Escape-StringWithSpaces -InputString "$CommitMessage #$CommitNumber"
        $svnCommand = "commit -m"
    }
    $svnCommitString = $svnCommand, $CommitMessage -join ' '
    return $svnCommitString
}
