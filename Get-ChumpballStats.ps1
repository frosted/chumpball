<#
.SYNOPSIS
    Scrapes stats for Chumpball fantasy basketball league and outputs report to HTML
.DESCRIPTION
    Scraping data from https://basketball.realgm.com/nba/stats/2024/Totals/All/points/All/desc/#/Regular_Season. The
    stats extend over several pages, so we have to loop through (replacing # with pages 1...?).  Each day there are
    tables added/removed depending on the games scheduled that day.  So far, the last table on the page is the stats 
    table.  Once the stats are retrieved, we apply a very custom rule set to divide players between teams A and B, 
    with a very custom ranking system (pts, ast, reb = 1, tov = -2).
.NOTES
    This has only been tested on Windows PowerShell.
.EXAMPLE
    Get-ChumpballStats -Verbose
    Does what it says.  Verbose will provide more information to your screen than you probably want.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $Push
)

$Script:rootFolder = $PSScriptRoot

start-transcript -Path "c:\get-chumpballstats.log"

#$rosterFile = $rootFolder + '\config\rosters.csv'
$requiredModules = @('JoinModule')

# dot-source all scripts
Get-ChildItem -Path "$rootFolder\scripts" -Filter *.ps1 -Recurse | ForEach-Object { . $_.FullName }

# import required modules
$requiredModules | ForEach-Object {
    If (!(Get-Module -Name $_)) {
        # install join module
        Install-Module $_ -AllowClobber
        Import-Module $_ -WarningAction SilentlyContinue
    }
}



# $rosterStats = Update-RosterStats -CSVFilePath "$rootFolder\config\rosters.csv" -Uri 'https://basketball.realgm.com/nba/stats/2024/Totals/All/points/All/desc/<#>/Regular_Season'
$rosterStats = Update-RosterStats -CSVFilePath "$rootFolder\config\rosters.csv" -Uri 'https://basketball.realgm.com/nba/stats/2024/Totals/All/points/All/desc/Regular_Season'

$teamStandings = Get-TeamStandings -Uri 'https://basketball.realgm.com/nba/standings'

$RosterStats = Add-RosterRanking -RosterInput $rosterStats -StandingsInput $teamStandings

If (Test-Path -Path "$rootFolder\config\bets.csv") {
    $bets = Import-Csv -Path "$rootFolder\config\bets.csv"
}

Write-StatsOutput -RosterInput $rosterStats -toHTML -AddTable $bets

If ($Push) {
    Set-Location $Script:rootFolder
    git config --global user.email "pe.frost@gmail.com"
    git config --global user.name "Ed"
    git status
    git add .
    git commit -m 'updated stats'
    git push
}

Stop-Transcript