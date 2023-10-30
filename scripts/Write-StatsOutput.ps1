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
                    @{Name = 'Average'; Expression = { [Math]::Round(($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamA' } | Measure-Object -Property FVPG -Sum | Select-Object -ExpandProperty Sum) / 5, 2) } }
                ))
        }
        # build team b summary
        $owners | ForEach-Object {
            $owner = $_.Owner
            $summaryObjectB.Add(($owner | Select-Object `
                    @{Name = 'Owner'; Expression = { $owner } }, `
                    @{Name = 'Score'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property FV -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Games'; Expression = { $RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property GP -Sum | Select-Object -ExpandProperty Sum } }, `
                    @{Name = 'Average'; Expression = { [Math]::Round(($RosterInput | Where-Object { $_.Owner -eq $owner -and $_.Assignment -eq 'TeamB' } | Measure-Object -Property FVPG -Sum | Select-Object -ExpandProperty Sum) / 5, 2) } }
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

        If ($toHTML) {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Chumpball Statistics</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * {
        box-sizing: border-box;
        }

        .row {
        display: flex;
        margin-left:0px;
        margin-right:0px;
        }

        .columna {
        flex: 50%;
        padding: 5px;
        }

        .columnb {
        flex: 70%;
        padding: 5px;
        }

        .columnc {
        flex: 30%;
        padding: 5px;
        }

        table {
            border-collapse: collapse;
            border-spacing: 0;
            width: 100%;
            border: 1px solid #ddd;
          }

        @charset "UTF-8";
        @import url(https://fonts.googleapis.com/css?family=Open+Sans:300,400,700);
        
        body {
          font-family: 'Open Sans', sans-serif;
          font-weight: 300;
          line-height: 1.42em;
          color:#A7A1AE;
          background-color:#1F2739;
        }
        
        h1 {
          font-size:3em; 
          font-weight: 300;
          line-height:1em;
          text-align: center;
          color: #4DC3FA;
        }
        
        h2 {
          font-size:1em; 
          font-weight: 300;
          text-align: center;
          display: block;
          line-height:1em;
          padding-bottom: 2em;
          color: #FB667A;
        }
        
        h2 a {
          font-weight: 700;
          text-transform: uppercase;
          color: #FB667A;
          text-decoration: none;
        }
        
        .blue { color: #185875; }
        .yellow { color: #FFF842; }
        
        .container th h1 {
              font-weight: bold;
              font-size: 1em;
          text-align: left;
          color: #185875;
        }
        
        .container td {
              font-weight: normal;
              font-size: 1em;
          -webkit-box-shadow: 0 2px 2px -2px #0E1119;
               -moz-box-shadow: 0 2px 2px -2px #0E1119;
                    box-shadow: 0 2px 2px -2px #0E1119;
        }
        
        .container {
              text-align: left;
              overflow: hidden;
              width: 95%;
              margin: 0 auto;
          display: table;
          padding: 0 0 8em 0;
        }
        
        .container td, .container th {
              padding-bottom: 2%;
              padding-top: 2%;
          padding-left:2%;  
        }
        
        /* Background-color of the odd rows */
        .container tr:nth-child(odd) {
              background-color: #323C50;
        }
        
        /* Background-color of the even rows */
        .container tr:nth-child(even) {
              background-color: #2C3446;
        }
        
        .container th {
              background-color: #1F2739;
        }
        
        .container td:first-child { color: #FB667A; }
        
        .container tr:hover {
           background-color: #464A52;
        -webkit-box-shadow: 0 6px 6px -6px #0E1119;
               -moz-box-shadow: 0 6px 6px -6px #0E1119;
                    box-shadow: 0 6px 6px -6px #0E1119;
        }
        
        .container td:hover {
          background-color: #FFF842;
          color: #403E10;
          font-weight: bold;
          
          box-shadow: #7F7C21 -1px 1px, #7F7C21 -2px 2px, #7F7C21 -3px 3px, #7F7C21 -4px 4px, #7F7C21 -5px 5px, #7F7C21 -6px 6px;
          transform: translate3d(6px, -6px, 0);
          
          transition-delay: 0s;
              transition-duration: 0.4s;
              transition-property: all;
          transition-timing-function: line;
        }
        
        @media (max-width: 800px) {
        .container td:nth-child(4),
        .container th:nth-child(4) { display: none; }
        }
        </style>
</head>
<body>
    <h1><span class="yellow">Chumpball</span> <span class="blue">Stats '23-'24</span> </h1>
    <div class="row">
        <div class="columna">
            [Team A Table]
        </div>
        <div class="columna">
            [Team B Table]
        </div>
    </div>
    <div class="row">
        <div class="columnb" style="overflow-x:auto;">
            <h1>Rosters</h1>
            [Team Rosters]
        </div>
        <div class="columnc">
            <h1>Leaderboard</h1>
            [Stat Leaders]
            <h1>Bets</H1>
            [Add Table]
        </div>
    </div>
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
            <td>$($_.Pts)</td>
            <td>$($_.Reb)</td>
            <td>$($_.Ast)</td>
            <td>$($_.TOV)</td>
            <td>$($_.FV)</td>
            <td>$([Math]::Round($_.FVPG,2))</td>
        </tr>
"@
                }
                $htmlBuild += @"
        <tr>
        <td colspan="4" Align="right"=>Team A Totals:</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property GP -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property PTS -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property REB -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property AST -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property TOV -sum).Sum)</td>
            <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property FV -sum).Sum)</td>
            <td>$([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamA'} | Measure-Object -Property FVPG -sum).Sum,2))</td>
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
                <td>$($_.Pts)</td>
                <td>$($_.Reb)</td>
                <td>$($_.Ast)</td>
                <td>$($_.TOV)</td>
                <td>$($_.FV)</td>
                <td>$([Math]::Round($_.FVPG,2))</td>
            </tr>
"@
                }
                $htmlBuild += @"
            <tr>
                <td colspan="4" Align="right"=>Team B Totals:</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property GP -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property PTS -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property REB -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property AST -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property TOV -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property FV -sum).Sum)</td>
                <td>$([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'TeamB'} | Measure-Object -Property FVPG -sum).Sum,2))</td>
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
                <td>$($_.Pts)</td>
                <td>$($_.Reb)</td>
                <td>$($_.Ast)</td>
                <td>$($_.TOV)</td>
                <td>$($_.FV)</td>
                <td>$([Math]::Round($_.FVPG,2))</td>
            </tr>
"@
                }
                $htmlBuild += @"
            <tr>
                <td colspan="4" Align="right"=>Bench Totals:</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property GP -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property PTS -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property REB -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property AST -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property TOV -sum).Sum)</td>
                <td>$(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property FV -sum).Sum)</td>
                <td>$([Math]::Round(($rosterStats | Where-Object {$_.Owner -eq $owner -and $_.Assignment -eq 'Bench'} | Measure-Object -Property FVPG -sum).Sum,2))</td>
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
                <th>Score</th>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
                <td>$($_.Value)</td>
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
        $summaryObjectA | Format-Table -AutoSize -RepeatHeader

        Write-Output '--------------------'
        Write-Output 'Team B Summary'
        Write-Output '--------------------' 
        $summaryObjectB | Format-Table -AutoSize -RepeatHeader
    }
}