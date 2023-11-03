Function Update-RosterStats {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $CSVFilePath,
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $Uri
    )

    # download all stats
    $statsDownload = Get-Stats -Uri $Uri

    # get league roster data
    $rosters = Import-Csv -Path $CSVFilePath
    $stats = $statsDownload | Select-Object *, @{Name = 'Name'; Expression = { $(($_.Player).Replace(',', '').Replace('.', '')) } }, @{Name = 'FV'; Expression = { [int]$_.PTS + [int]$_.AST + [int]$_.REB - ([int]$_.TOV * 2) } } | Select-Object *, @{Name = 'FVPG'; Expression = { ([int]$_.FV / [int]$_.GP) } } -ExcludeProperty Player, Rank, Team, Pos, '#' | `
        Select-Object -Unique Name, @{Name = 'GP'; Expression = { [int]$_.GP } }, MIN, @{Name = 'PTS'; Expression = { [int]$_.PTS } }, @{Name = 'REB'; Expression = { [int]$_.REB } }, @{Name = 'AST'; Expression = { [int]$_.AST } }, @{Name = 'TOV'; Expression = { [int]$_.TOV } }, FV, FVPG
    Return (LeftJoin-Object -LeftObject $($rosters | Select-Object * -ExcludeProperty Value) -RightObject $stats -On Name)
}