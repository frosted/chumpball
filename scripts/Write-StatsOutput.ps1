Function Write-StatsOutput {
    [CmdletBinding()]
    param(
        [parameter()]
        [object]
        $RosterInput,
        [parameter()]
        [switch]
        $toHTML,
        [parameter()]
        [object]
        $AddTable
    )
    begin {
        $summaryObjectA = [System.Collections.Generic.List[object]]::new()
        $summaryObjectB = [System.Collections.Generic.List[object]]::new()
    }
    process {
        $owners = $rosterInput | Select-Object -Unique Owner
        # build team a summary
        $owners | ForEach-Object {
            $owner = $_.Owner
            $summaryObjectA.Add(($owner | Select-Object `
                    @{Name = 'Owner'; Expression = { $owner } }, `
                    @{Name = 'Score'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property FV -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Games'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property GP -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Missed'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property Missed -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Average'; Expression = { ([Math]::Round(( ($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property FV -Sum | Select-Object -ExpandProperty Sum) / ($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property GP -Sum | Select-Object -ExpandProperty Sum) ), 2) ).ToString("F2") } }
                ))
        }
        # build team b summary
        $owners | ForEach-Object {
            $owner = $_.Owner
            $summaryObjectB.Add(($owner | Select-Object `
                    @{Name = 'Owner'; Expression = { $owner } }, `
                    @{Name = 'Score'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property FV -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Games'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property GP -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Missed'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property Missed -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Average'; Expression = { ([Math]::Round(( ($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property FV -Sum | Select-Object -ExpandProperty Sum) / ($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property GP -Sum | Select-Object -ExpandProperty Sum) ), 2)).ToString("F2") } }
                ))
        }
        
        # ranking team a
        $rank = 0
        $summaryObjectA = $summaryObjectA | Sort-Object Score -Descending | Select-Object @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, *

        # ranking team b
        $rank = 0
        $summaryObjectB = $summaryObjectB | Sort-Object Score -Descending | Select-Object @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, *

        # ranking fv
        $rank = 0
        $summaryTopFV = $RosterInput | Sort-Object FV -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.FV } }

        # ranking fvpg
        $rank = 0
        $summaryTopFVPG = $RosterInput | Sort-Object FVPG -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.FVPG } }

        # ranking pts
        $rank = 0
        $summaryTopPTS = $RosterInput | Sort-Object PTS -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.PTS } }

        # ranking reb
        $rank = 0
        $summaryTopREB = $RosterInput | Sort-Object REB -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.REB } }

        # ranking ast
        $rank = 0
        $summaryTopAST = $RosterInput | Sort-Object AST -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.AST } }

        # ranking tov
        $rank = 0
        $summaryTopTOV = $RosterInput | Sort-Object TOV -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.TOV } }

        # ranking missed
        $rank = 0
        $summaryTopMissed = $RosterInput | Sort-Object Missed -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.Missed } }

        # ranking centers
        $rank = 0
        $summaryTopCenters = $RosterInput | Where-Object Pos -eq C | Sort-Object FV -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.FV } }

        # ranking forwards
        $rank = 0
        $summaryTopForwards = $RosterInput | Where-Object Pos -eq F | Sort-Object FV -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.FV } }

        # ranking guards
        $rank = 0
        $summaryTopGuards = $RosterInput | Where-Object Pos -eq G | Sort-Object FV -Descending | Select-Object -First 5 @{ 
            Name = '#'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank }
        }, Name, Team, Round, @{Name = 'Value'; Expression = { $_.FV } }

        # html report
        $strDateTime = Get-Date -Format yyyyMMddhhmmss
        If ($toHTML) {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Chumpball Statistics</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="cache-control" content="no-cache, must-revalidate, post-check=0, pre-check=0" />
    <meta http-equiv="expires" content="0" />
    <meta http-equiv="pragma" content="no-cache" />
    <link rel="stylesheet" href="https://frosted.github.io/chumpball/scripts/style-two-column.css?v=$($strDateTime)">
</head>
<body>
    <header>
        <p class="logo"><span class="yellow">Chumpball</span> Fantasy Basketball</p>
        <input id="nav" type="checkbox">
        <label for="nav"></label>
        <nav>
            <ul>
                <li><a href="#cb-summary">Summary</a></li>
                <li><a href="#cb-rosters">Rosters</a></li>
                <li><a href="#cb-leaderboards">Leaderboards</a></li>
                <li><a href="#cb-bets">Bets</a></li>
            </ul>
        </nav>
    </header>

    <a id="cb-summary"><span class="invisible">A</span></a>
    <br><br><br>
    <div class="responsive-two-column-grid">
        <div>
            [Team A Table]
        </div>
        <div>
            [Team B Table]
        </div>
    </div>
    <div class="responsive-two-column-grid">
        <div>
            <a id="cb-rosters"><span class="invisible">#</span></a>
            <h1>Rosters</h1>
            [Team Rosters]
        </div>
        <div>
            <a id="cb-leaderboards"><span class="invisible">#</span></a>
            <h1>Leaderboards</h1>
            [Stat Leaders]
            <h1>Bets</H1>
            <a id="cb-bets"></a>
            [Add Table]
        </div>
    </div>
    <footer>
        <p align="center">2023-2024 season stats last updated: $(Get-Date)</p>
    </footer>
</body>
</html>
"@

            # build team a summary table
            $htmlBuild = @"
            <table class="container">
                <tr>
                    <th>#</th>
                    <th>Owner</th>
                    <th>Games</th>
                    <th>Missed</th>
                    <th>Team A</th>
                    <th>Average</th>
                </tr>
"@
            For ($i = 1; $i -le $owners.count; $i++) {
                $htmlBuild += @"
                <tr>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'#')</td>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'Owner')</td>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'Games')</td>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'Missed')</td>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'Score')</td>
                    <td>$(($summaryObjectA | Where-Object {$_.'#' -eq $i}).'Average')</td>
                </tr>
"@
            }

            $htmlBuild += @"
            </table>
"@

            $html = $html.Replace('[Team A Table]', $htmlBuild)

            # build team b summary table
            $htmlBuild = @"
            <table class="container">
                <tr>
                    <th>#</th>
                    <th>Owner</th>
                    <th>Games</th>
                    <th>Missed</th>
                    <th>Team B</th>
                    <th>Average</th>
                </tr>
"@
            For ($i = 1; $i -le $owners.count; $i++) {
                $htmlBuild += @"
                <tr>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'#')</td>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'Owner')</td>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'Games')</td>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'Missed')</td>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'Score')</td>
                    <td>$(($summaryObjectB | Where-Object {$_.'#' -eq $i}).'Average')</td>
                </tr>
"@
            }

            $htmlBuild += @"
            </table>
"@

            $html = $html.Replace('[Team B Table]', $htmlBuild)

            $htmlBuild = $null

            $htmlBuildH = @"
        <tr>
            <th>Player</th>
            <th>Team</th>
            <th>Pos</th>
            <th>Rd</th>
            <th>GP</th>
            <th>MIA</th>
            <th>Pts</th>
            <th>Reb</th>
            <th>Ast</th>
            <th>TO</th>
            <th>Score</th>
            <th>Avg</th>
        </tr>
"@

            foreach ($owner in $owners.Owner) {
                $htmlBuild += @"
    <table class="container">
        <tr>
            <th colspan="11">Owner: $($owner)</th>
        </tr>
"@
                $htmlBuild += $htmlBuildH
                $rosterStats | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Sort-Object -Property Pos  | ForEach-Object {
                    $htmlBuild += @"
        <tr>
            <td>$($_.Name)</td>
            <td>$($_.Team)</td>
            <td>$($_.Pos)</td>
            <td>$($_.Round)</td>
            <td>$($_.GP)</td>
            <td>$($_.Missed)</td>
            <td>$($_.Pts)</td>
            <td>$($_.Reb)</td>
            <td>$($_.Ast)</td>
            <td>$($_.TOV)</td>
            <td>$($_.FV)</td>
            <td>$(([Math]::Round($_.FVPG,2)).ToString("F2"))</td>
        </tr>
"@
                }
                $htmlBuild += @"
        <tr>
        <td colspan="4" Align="right"=>Team A Totals:</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property GP -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property Missed -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property PTS -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property REB -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property AST -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property TOV -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property FV -sum).Sum)</td>
            <td>$(([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property FVPG -sum).Sum,2)).ToString("F2"))</td>
        </tr>
"@
                $rosterStats | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Sort-Object -Property Pos  | ForEach-Object {
                    $htmlBuild += @"
            <tr>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Pos)</td>
                <td>$($_.Round)</td>
                <td>$($_.GP)</td>
                <td>$($_.Missed)</td>
                <td>$($_.Pts)</td>
                <td>$($_.Reb)</td>
                <td>$($_.Ast)</td>
                <td>$($_.TOV)</td>
                <td>$($_.FV)</td>
                <td>$(([Math]::Round($_.FVPG,2)).ToString("F2"))</td>
            </tr>
"@
                }
                $htmlBuild += @"
            <tr>
                <td colspan="4" Align="right"=>Team B Totals:</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property GP -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property Missed -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property PTS -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property REB -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property AST -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property TOV -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property FV -sum).Sum)</td>
                <td>$(([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property FVPG -sum).Sum,2)).ToString("F2"))</td>
            </tr>
"@
                $rosterStats | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'Bench' } | Sort-Object -Property Pos  | ForEach-Object {
                    $htmlBuild += @"
            <tr>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Pos)</td>
                <td>$($_.Round)</td>
                <td>$($_.GP)</td>
                <td>$($_.Missed)</td>
                <td>$($_.Pts)</td>
                <td>$($_.Reb)</td>
                <td>$($_.Ast)</td>
                <td>$($_.TOV)</td>
                <td>$($_.FV)</td>
                <td>$(([Math]::Round($_.FVPG,2)).ToString("F2"))</td>
            </tr>
"@
                }
                $htmlBuild += @"
            <tr>
                <td colspan="4" Align="right"=>Bench Totals:</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property GP -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property Missed -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property PTS -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property REB -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property AST -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property TOV -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property FV -sum).Sum)</td>
                <td>$(([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property FVPG -sum).Sum,2)).ToString("F2"))</td>
            </tr>
        </table>
"@

            }

            $html = $html.Replace('[Team Rosters]', $htmlBuild)

            # stat leaders
            $htmlBuildH = @"
        <table class="container">
            <tr>
                <th colspan="5">[stat heading]</th>
            </tr>
            <tr>
                <th>#</th>
                <th>Player</th>
                <th>Team</th>
                <th>Round</th>
                <th>Value</th>
            </tr>
"@
            $htmlBuild = $htmlBuildH.Replace('[stat heading]', 'Score')
            $summaryTopFV | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@            
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Average')
            $summaryTopFVPG | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Points')
            $summaryTopPts | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Rebounds')
            $summaryTopREB | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Assists')
            $summaryTopAST | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Turnovers')
            $summaryTopTOV | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Turnovers')
            $summaryTopTOV | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Missed Games')
            $summaryTopMissed | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Top Centers')
            $summaryTopCenters | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Top Forwards')
            $summaryTopForwards | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $htmlBuild += $htmlBuildH.Replace('[stat heading]', 'Top Guards')
            $summaryTopGuards | ForEach-Object { 
                $htmlBuild += @"
            <tr>
                <td>$($_.'#')</td>
                <td>$($_.Name)</td>
                <td>$($_.Team)</td>
                <td>$($_.Round)</td>
                <td>$([Math]::Round($_.Value))</td>
            </tr>
"@
            }
            $htmlBuild += @"
        </table>
"@
            $html = $html.Replace('[Stat Leaders]', $htmlBuild)

            If ($AddTable) {
                $columnCount = $AddTable | Get-Member | Where-Object MemberType -eq NoteProperty | Measure-Object | Select-Object -ExpandProperty Count
                $htmlBuild = $AddTable | ConvertTo-Html -Fragment -As List
                $htmlBuild = $htmlBuild.replace('<table>', '<table class="container">')
                $htmlBuild = $htmlBuild.replace('<td><hr>', '<td colspan="' + $($ColumnCount) + '"><hr>')
                $html = $html.replace('[Add Table]', $htmlBuild)
            } Else {
                $html = $html.Replace('[Add Table]', '<p>No bets yet.</p>')
            }
            # write out to html
            $html | Set-Content -Path $Script:rootFolder\chumpballstats.html -Force 

            Write-Verbose "Report saved to $Script:rootFolder\chumpballstats.html"
        } 

    }
    End {

        Write-Output '--------------------'
        Write-Output 'Team A Summary'
        Write-Output '--------------------'
        $summaryObjectA | Format-Table -AutoSize

        Write-Output '--------------------'
        Write-Output 'Team B Summary'
        Write-Output '--------------------' 
        $summaryObjectB | Format-Table -AutoSize
    }
}