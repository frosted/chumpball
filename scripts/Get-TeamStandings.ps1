Function Get-TeamStandings {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Uri
    )

    begin { 
        $standingsDownload = $null
    }
    
    process {
        # scrape data

        $webResponse = Invoke-WebRequest -Method GET -Uri $uri
        $targetTable = ($webresponse.ParsedHtml.getElementsByTagName('table') | Measure-Object).Count - 1
        $standingsDownload = ConvertFrom-HtmlTable -WebRequest $webResponse -TableNumber ($targetTable - 1)
        $standingsDownload += ConvertFrom-HtmlTable -WebRequest $webResponse -TableNumber $targetTable
        
        $standingsDownload = $standingsDownload | ForEach-Object { $_ | Select-Object *,
            @{Name = 'tm'; expression = {
                    Switch ($_.Team) {
                        'Boston Celtics' { "BOS" }
                        'Philadelphia Sixers' { "PHI" }
                        'Atlanta Hawks' { "ATL" }
                        'Indiana Pacers' { "IND" }
                        'Brooklyn Nets' { "BKN" }
                        'Milwaukee Bucks' { "MIL" }
                        'Orlando Magic' { "ORL" }
                        'Detroit Pistons' { "DET" }
                        'Chicago Bulls' { "CHI" }
                        'Cleveland Cavaliers' { "CLE" }
                        'New York Knicks' { "NYK" }
                        'Toronto Raptors' { "TOR" }
                        'Charlotte Hornets' { "CHA" }
                        'Washington Wizards' { "WAS" }
                        'Miami Heat' { "MIA" }
                        'Dallas Mavericks' { "DAL" }
                        'Golden State Warriors' { "GSW" }
                        'Denver Nuggets' { "DEN" }
                        'New Orleans Pelicans' { "NOR" }
                        'Los Angeles Lakers' { "LAL" }
                        'Los Angeles Clippers' { "LAC" }
                        'Oklahoma City Thunder' { "OKC" }
                        'Minnesota Timberwolves' { "MIN" }
                        'San Antonio Spurs' { "SAS" }
                        'Sacramento Kings' { "SAC" }
                        'Phoenix Suns' { "PHO" }
                        'Utah Jazz' { "UTA" }
                        'Portland Trail Blazers' { "POR" }
                        'Houston Rockets' { "HOU" }
                        'Memphis Grizzlies' { "MEM" }
                    }
                }
            },
            @{name = 'gp'; expression = { $([int]$_.W + [int]$_.L) } }
        }
    }

    end {
        Return $standingsDownload
    }
}