#region: variable declaration
$year = 2026
#$scriptRoot = 'C:\.code\GIT\Chumpball'
$scriptRoot = $PSScriptRoot

#endregion

#region: modules & functions

function Add-RankMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [array]
        $ListObject,
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $SortByProperty,
        [Parameter()]
        [switch]
        $Descending
    )

    #$listObject | Sort-Object Score -Descending | ForEach-Object {
    #            $_ | Add-Member -NotePropertyName "#" -NotePropertyValue $([int]$rank++) -ErrorAction Stop
    #        }
    [System.Collections.Generic.List[pscustomobject]]$output = @()
    $rank = 1

    $ListObject | Sort-Object $($SortByProperty) -Descending | ForEach-Object {
        $row = $_ | Select-Object @{n='#'; e={$([int]$rank)}},*
        $output.Add($row)
        $rank++
    }
    
    Return $($output | Sort-Object -Property '#')
}

$requiredModules = @('Join-Object','PSWriteHTML')
ForEach ($module in $requiredModules) {
    Try {
        # Find-Module $module -ErrorAction Stop | Install-Module -Scope CurrentUser 
        Import-Module $module -Force
    } Catch {
        Write-Output "Unable to install required module $module.  Please remediate, and try again."
    }
}

# import from local source due to issues importing in GH Actions
#Import-Module -FullyQualifiedName "$scriptRoot\modules\Join-Object\2.0.3\Join-Object.psd1"
#Import-Module -FullyQualifiedName "$scriptRoot\modules\PSWriteHTML\1.39.0\PSWriteHTML.psd1"
#Import-Module -FullyQualifiedName "$scriptRoot\modules\PSWriteHTML\1.9.0\PSWriteHTML.psd1"
#Import-Module -FullyQualifiedName "$scriptRoot\modules\Microsoft.PowerShell.Management\Microsoft.PowerShell.Management.psd1"
#Import-Module -FullyQualifiedName "$scriptRoot\modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1"
. $scriptRoot\Get-PlayerData.ps1

#endregion

#region: pull content

$dataPlayer = Get-PlayerData -Year $year -StoredQuery PlayerData
$dataSeason = Get-PlayerData -Year $year -StoredQuery SeasonData
$dataDraft = Get-Content -Path "$scriptRoot\config\$($year)_draft.json" | ConvertFrom-Json 

#endregion

#region: join datasets
$joinSplat = @{
    Left              = $dataPlayer
    LeftJoinProperty  = 'Player'
    Right             = $dataSeason
    RightJoinProperty = 'Player'
    ExcludeLeftProperties = 'Number','Team','SearchKey' 
    ExcludeRightProperties = 'Searchkey' 
    AllowColumnsMerging = $true
    DataTable = $true
    Type = 'AllInLeft'
}
$data_player_season = Join-Object @joinSplat

$joinSplat = @{
    Left              = $data_player_season
    LeftJoinProperty  = 'Player'
    Right             = $datadraft
    RightJoinProperty = 'Player'
    ExcludeLeftProperties = 'Pos'
    AllowColumnsMerging = $true
    DataTable = $true
    Type = 'OnlyIfInBoth'
}
$data_player_season_draft_drafted = Join-Object @joinSplat
#$data_player_season_draft_undrafted = Join-Object @joinSplat

#endregion

#region: prepare data for calculation

$data_player_season_draft_drafted = $data_player_season_draft_drafted | Select-Object Age,DraftStatus,HT,Nationality,Number,Pick,Player,Pos,PreDraftTeam,Owner,Rank,'Rd#',Team,WT,YOS, `
@{n='3P'; e = {if ($_.'3P' -like '') {0} else {[int]$_.'3P'}}}, `
@{n='3PA'; e = {if ($_.'3PA' -like '') {0} else {[int]$_.'3PA'}}}, `
@{n='3PM'; e = {if ($_.'3PM' -like '') {0} else {[int]$_.'3PM'}}}, `
@{n='AST'; e = {if ($_.'AST' -like '') {0} else {[int]$_.'AST'}}}, `
@{n='AVG'; e = {if ($_.'AVG' -like '') {0} else {[int]$_.'AVG'}}}, `
@{n='BLK'; e = {if ($_.'BLK' -like '') {0} else {[int]$_.'BLK'}}}, `
@{n='DRB'; e = {if ($_.'DRB' -like '') {0} else {[int]$_.'DRB'}}}, `
@{n='FG'; e = {if ($_.'FG' -like '') {0} else {[int]$_.'FG'}}}, `
@{n='FGA'; e = {if ($_.'FGA' -like '') {0} else {[int]$_.'FGA'}}}, `
@{n='FGM'; e = {if ($_.'FGM' -like '') {0} else {[int]$_.'FGM'}}}, `
@{n='FT'; e = {if ($_.'FT' -like '') {0} else {[int]$_.'FT'}}}, `
@{n='FTA'; e = {if ($_.'FTA' -like '') {0} else {[int]$_.'FTA'}}}, `
@{n='FTM'; e = {if ($_.'FTM' -like '') {0} else {[int]$_.'FTM'}}}, `
@{n='GP'; e = {if ($_.'GP' -like '') {0} else {[int]$_.'GP'}}}, `
@{n='MIN'; e = {if ($_.'MIN' -like '') {0} else {[int]$_.'MIN'}}}, `
@{n='ORB'; e = {if ($_.'ORB' -like '') {0} else {[int]$_.'ORB'}}}, `
@{n='PF'; e = {if ($_.'PF' -like '') {0} else {[int]$_.'PF'}}}, `
@{n='PTS'; e = {if ($_.'PTS' -like '') {0} else {[int]$_.'PTS'}}}, `
@{n='REB'; e = {if ($_.'REB' -like '') {0} else {[int]$_.'REB'}}}, `
@{n='Score'; e = {if ($_.'Score' -like '') {0} else {[int]$_.'Score'}}}, `
@{n='STL'; e = {if ($_.'STL' -like '') {0} else {[int]$_.'STL'}}}, `
@{n='TOV'; e = {if ($_.'TOV' -like '') {0} else {[int]$_.'TOV'}}}

#endregion

#region: calculate team data

$dataOwners = $data_player_season_draft_drafted | Sort-Object -Property Pick | Select-Object -Unique -ExpandProperty 'Owner'

[System.Collections.Generic.List[psObject]]$teamA = @()
[System.Collections.Generic.List[psObject]]$teamB = @()
[System.Collections.Generic.List[psObject]]$teamC = @()

foreach ($owner in $dataOwners) {
    $arrC = $data_player_season_draft_drafted | Where-Object { $_.'Owner' -eq $owner -and $_.pos -eq 'C' } | Sort-Object -Property Score -Descending
    $arrF = $data_player_season_draft_drafted | Where-Object { $_.'Owner' -eq $owner -and $_.pos -eq 'F' } | Sort-Object -Property Score -Descending
    $arrG = $data_player_season_draft_drafted | Where-Object { $_.'Owner' -eq $owner -and $_.pos -eq 'G' } | Sort-Object -Property Score -Descending

    $teamA.Add($arrC[0])
    $teamA.Add($arrF[0])
    $teamA.Add($arrF[1])
    $teamA.Add($arrG[0])
    $teamA.Add($arrG[1])

    $teamB.Add($arrC[1])
    $teamB.Add($arrF[2])
    $teamB.Add($arrF[3])
    $teamB.Add($arrG[2])
    $teamB.Add($arrG[3])

    $arrC + $arrF + $arrG | Where-Object {$_ -notin $teamA -and $_ -notin $teamB} | ForEach-Object {$teamC.Add($_)}
}

# team A totals
[System.Collections.Generic.List[psobject]]$teamAStats = @()
[System.Collections.Generic.List[psobject]]$teamASum = @()
foreach ($owner in $dataOwners) {
    $ownStats = $teamA | Sort-Object Pos,Score | Where-Object 'Owner' -eq $owner | Select-Object Player, Owner, Team, Pos, 'Rd#', `
        @{n='GP'; e= {$_.'GP'}}, `
        @{n='PTS'; e= {$_.'PTS'}}, `
        @{n='REB'; e= {$_.'REB'}}, `
        @{n='AST'; e= {$_.'AST'}}, `
        @{n='TOV'; e= {$_.'TOV'}}, `
        @{n='Score'; e= {$_.'Score'}}, `
        @{n='AVG'; e= {$_.'AVG'}
    }
    
    $ownSum = '' | Select-Object `
        @{n='Player'; e= {}}, `
        @{n='Owner'; e= {$owner}}, `
        @{n='Team'; e= {"Team A Totals:"}}, `
        @{n='Pos'; e= {''}}, `
        @{n='Rd#'; e= {''}}, `
        @{n='GP'; e=    {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property GP -sum).sum}}, `
        @{n='PTS'; e=   {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property PTS -sum).sum}}, `
        @{n='REB'; e=   {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property REB -sum).sum}}, `
        @{n='AST'; e=   {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AST -sum).sum}}, `
        @{n='TOV'; e=   {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property TOV -sum).sum}}, `
        @{n='Score'; e= {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property Score -sum).sum}}, `
        @{n='AVG'; e=   {[int]($teamA | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AVG -sum).sum}
    } 

    $teamAStats.Add($ownStats)
    $teamASum.Add($ownSum)
}

# team B totals
[System.Collections.Generic.List[psobject]]$teamBStats = @()
[System.Collections.Generic.List[psobject]]$teamBSum = @()
foreach ($owner in $dataOwners) {
    $ownStats = $teamB | Sort-Object Pos,Score | Where-Object 'Owner' -eq $owner | Select-Object Player, Owner, Team, Pos, 'Rd#', `
        @{n='GP'; e= {$_.'GP'}}, `
        @{n='PTS'; e= {$_.'PTS'}}, `
        @{n='REB'; e= {$_.'REB'}}, `
        @{n='AST'; e= {$_.'AST'}}, `
        @{n='TOV'; e= {$_.'TOV'}}, `
        @{n='Score'; e= {$_.'Score'}}, `
        @{n='AVG'; e= {$_.'AVG'}
    }
    
    $ownSum = '' | Select-Object `
        @{n='Player'; e= {}}, `
        @{n='Owner'; e= {$owner}}, `
        @{n='Team'; e= {"Team A Totals:"}}, `
        @{n='Pos'; e= {''}}, `
        @{n='Rd#'; e= {''}}, `
        @{n='GP'; e=    {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property GP -sum).sum}}, `
        @{n='PTS'; e=   {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property PTS -sum).sum}}, `
        @{n='REB'; e=   {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property REB -sum).sum}}, `
        @{n='AST'; e=   {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AST -sum).sum}}, `
        @{n='TOV'; e=   {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property TOV -sum).sum}}, `
        @{n='Score'; e= {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property Score -sum).sum}}, `
        @{n='AVG'; e=   {[int]($teamB | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AVG -sum).sum}
    } 

    $teamBStats.Add($ownStats)
    $teamBSum.Add($ownSum)
}

# team C totals
[System.Collections.Generic.List[psobject]]$teamCStats = @()
[System.Collections.Generic.List[psobject]]$teamCSum = @()
foreach ($owner in $dataOwners) {
    $ownStats = $teamC | Sort-Object Pos,Score | Where-Object 'Owner' -eq $owner | Select-Object Player, Owner, Team, Pos, 'Rd#', `
        @{n='GP'; e= {$_.'GP'}}, `
        @{n='PTS'; e= {$_.'PTS'}}, `
        @{n='REB'; e= {$_.'REB'}}, `
        @{n='AST'; e= {$_.'AST'}}, `
        @{n='TOV'; e= {$_.'TOV'}}, `
        @{n='Score'; e= {$_.'Score'}}, `
        @{n='AVG'; e= {$_.'AVG'}
    }
    
    $ownSum = '' | Select-Object `
        @{n='Player'; e= {}}, `
        @{n='Owner'; e= {$owner}}, `
        @{n='Team'; e= {"Team C Totals:"}}, `
        @{n='Pos'; e= {''}}, `
        @{n='Rd#'; e= {''}}, `
        @{n='GP'; e=    {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property GP -sum).sum}}, `
        @{n='PTS'; e=   {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property PTS -sum).sum}}, `
        @{n='REB'; e=   {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property REB -sum).sum}}, `
        @{n='AST'; e=   {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AST -sum).sum}}, `
        @{n='TOV'; e=   {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property TOV -sum).sum}}, `
        @{n='Score'; e= {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property Score -sum).sum}}, `
                            @{n='AVG'; e=   {[int]($teamC | Where-Object {$_.'Owner' -eq $owner} | Measure-Object -Property AVG -sum).sum}
                        } 

                        $teamCStats.Add($ownStats)
                        $teamCSum.Add($ownSum)
                    }
#endregion

#region: style

#Add-CSS -Placement Inline -Content 'td.shrink { white-space: nowrap; }' -ResourceComment 'Prevents wrapping, forcing cell to expand if content is long'
#Add-CSS -Placement Inline -Content 'td.expand { width: 99%; }' -ResourceComment 'Occupies remaining space after other columns shrink'
#Add-CSS -Placement Inline -Content 'th, td { text-align: left;}'
#
#Add-CSS -Placement Inline -Content 'table { border-collapse: collapse; table-layout: auto; width: auto; max-width: 100%; }'
# Add-CSS -Placement Inline -Content 'table { table-layout: auto; }' -ResourceComment 'Let columns size based on content'
# Add-CSS -Placement Inline -Content 'table { width: auto; }' -ResourceComment 'Allow natural width'
# Add-CSS -Placement Inline -Content 'table { max-width: 100%; }' -ResourceComment 'Prevent overflow of container'

#endregion

#region: output

Dashboard -TitleText "Chumpball Fantasy Basketball $($year-1)-$($year)" -Author 'Ed Frost' -FilePath "$scriptRoot\index.html" {
    # Add-CSS -Content 'td.shrink { white-space: nowrap; }' -ResourceComment 'Prevents wrapping, forcing cell to expand if content is long'
    # Add-CSS -Content 'td.expand { width: 99%; }' -ResourceComment 'Occupies remaining space after other columns shrink'
    # Add-CSS -Content 'th { text-align: left;}'
    # Add-CSS -Content 'table { border-collapse: collapse; table-layout: auto; width: auto; max-width: 100%; }'
    Section -HeaderText "Chumpball Fantasy Basketball $($year-1)-$($year)" -BorderRadius 0px -HeaderTextColor BlackPearl -HeaderBackGroundColor White -HeaderTextSize 18 -HeaderTextAlignment left -content { 
        Section -Invisible -Density Compact -BorderRadius 0px -Content {
            foreach ($owner in $dataOwners) {
                Section -HeaderText "$owner" -BorderRadius 0px -Density Compact -HeaderBackGroundColor BlackPearl -HeaderTextAlignment center -Content {
                    #Text -FontSize 18 -FontWeight bold -Display contents -Alignment center -SkipParagraph -Text "$($owner)'s Team:"
                    
                    foreach ($team in @('A','B','C')) {
                        $dataTeamStats = [psobject](Get-Variable -Name "team$($team)Stats").Value | Where-Object {$_.owner -eq $owner}
                        $dataTeamSum = [psobject](Get-Variable -Name "team$($team)Sum").Value | Where-Object {$_.owner -eq $owner}
                        
                        Table -DataTable $($dataTeamStats + $dataTeamSum) -Title "$($owner)'s Team $($team):" -IncludeProperty 'Player','Team','Pos','Rd#','GP','PTS','REB','AST','TOV','SCORE','AVG' -Simplify  -HideFooter {
                            TableHeader -Title "Team $($team):"
                            TableContent -RowIndex $($dataTeamStats + $dataTeamSum).Count -FontWeight bold -
                        }      
                    } 
                }
            }
        }
        
        Section -Density Compact -BorderRadius 0px -HeaderText "Leaderboards" -HeaderBackGroundColor BlackPearl -HeaderTextAlignment center -content {
            Section -Density Compact -Margin 0 -BorderRadius 0px -HeaderText "Standings" -HeaderTextAlignment center -HeaderTextColor BlackPearl -HeaderBackGroundColor WhiteSmoke -content {
                SectionOption -RemoveShadow
                # team a standings
                $data = Add-RankMember -ListObject $teamASum -SortByProperty Score
                
                Table -DataTable $data -Width 300 -IncludeProperty '#', Owner, Score, GP, AVG -Simplify -HideFooter {
                    TableHeader -Title 'Team A'
                }

                # team b standings
                $data = Add-RankMember -ListObject $teamBSum -SortByProperty Score

                Table -DataTable $data -Width 300 -IncludeProperty '#', Owner, Score, GP, AVG -Simplify -HideFooter {
                    TableHeader -Title 'Team B'
                }

                # team a+b standings
                $data = $teamASum | Select-Object Owner, `
                    @{n='Score';e = {$thisVar = $_; $_.Score + $teamBSum.Where({$thisVar.owner -eq $owner}).Score}}, `
                    @{n='GP';e = {$thisVar = $_; $_.GP + $teamBSum.Where({$thisVar.owner -eq $owner}).GP}}, `
                    @{n='AVG';e = {$thisVar = $_; $_.AVG + $teamBSum.Where({$thisVar.owner -eq $owner}).AVG}
                }  | Sort-Object Score -Descending
                $data = Add-RankMember -ListObject $data -SortByProperty Score

                Table -DataTable $data -Width 300 -IncludeProperty '#', Owner, Score, GP, AVG -Simplify -HideFooter {
                    TableHeader -Title 'Team A+B'
                }
            }

            Section -Density Compact -Margin 0 -BorderRadius 0px -HeaderText "Positional Leaders" -HeaderTextAlignment center -HeaderTextColor BlackPearl -HeaderBackGroundColor WhiteSmoke -content {
                SectionOption -RemoveShadow -HeaderBackGroundColor White
            
                # top 5 centers
                $data = $data_player_season_draft_drafted | Where-Object Pos -eq 'C' | Sort-Object -Property Score -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty Score
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, Score -Simplify -HideFooter {
                    TableHeader -Title 'Top Centers'
                }

                # top 5 forwards
                $data = $data_player_season_draft_drafted | Where-Object Pos -eq 'F' | Sort-Object -Property Score -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty Score
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, Score -Simplify -HideFooter {
                    TableHeader -Title 'Top Forwards'
                }

                # top 5 guards
                $data = $data_player_season_draft_drafted | Where-Object Pos -eq 'G' | Sort-Object -Property Score -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty Score
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, Score -Simplify -HideFooter {
                    TableHeader -Title 'Top Guards'
                }
            }

            Section -Density Compact -Margin 0 -BorderRadius 0px -HeaderText "Stat Leaders" -HeaderTextAlignment center -HeaderTextColor BlackPearl -HeaderBackGroundColor WhiteSmoke -content {
                SectionOption -RemoveShadow -HeaderBackGroundColor White
            
                # top 5 score
                $data = $data_player_season_draft_drafted | Sort-Object -Property Score -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty Score
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, Score -Simplify -HideFooter {
                    TableHeader -Title 'Top Scores'
                }

                # top 5 average
                $data = $data_player_season_draft_drafted | Sort-Object -Property AVG -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty AVG
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, AVG -Simplify -HideFooter {
                    TableHeader -Title 'Top Averages'
                }

                # top 5 points
                $data = $data_player_season_draft_drafted | Sort-Object -Property PTS -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty PTS
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, PTS -Simplify -HideFooter {
                    TableHeader -Title 'Top Points'
                }

                # top 5 rebounds
                $data = $data_player_season_draft_drafted | Sort-Object -Property REB -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty REB
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, REB -Simplify -HideFooter {
                    TableHeader -Title 'Top Rebounds'
                }

                # top 5 assists
                $data = $data_player_season_draft_drafted | Sort-Object -Property AST -Descending | Select-Object * -First 5 
                $data = Add-RankMember -ListObject $data -SortByProperty AST
                Table -DataTable $data -Width 300 -IncludeProperty '#', Player, Team, AST -Simplify -HideFooter {
                    TableHeader -Title 'Top Assists'
                }
            }
        }

        Section -Invisible {
            # spacer
        }
    }
    
    Text -Text "Dashboard timestamp: $(get-date)" -Opacity 50          
} -ShowHTML

#endregion

