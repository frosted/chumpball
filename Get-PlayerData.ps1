function Get-PlayerData {
    [CmdletBinding()]
    param (
        [string]$Year = (Get-Date -Format 'yyyy'),
        [ValidateSet('SeasonData', 'PlayerData', 'PreseasonData')]
        $StoredQuery = 'SeasonData'
    )
    
    begin {
        ### Configure Classes

        Class PlayerStats {
            [int]$Number
            [string]$Player
            [string]$Team
            [int]$GP = 0
            [double]$MIN = 0
            [int]$PTS = 0
            [int]$FGM = 0
            [int]$FGA = 0
            [double]$FG = 0
            [int]$3PM = 0
            [int]$3PA = 0
            [double]$3P = 0
            [int]$FTM = 0
            [int]$FTA = 0
            [double]$FT = 0
            [int]$ORB = 0
            [int]$DRB = 0
            [int]$REB = 0
            [int]$AST = 0
            [int]$STL = 0
            [int]$BLK = 0
            [int]$TOV = 0
            [int]$PF = 0
            [int]$Score = 0
            [int]$AVG = 0
            [string]$SearchKey
            [string]$Rank
        }

        Class PlayerCard {
            [int]$Number
            [string]$Player
            [string]$Pos
            [string]$HT
            [int]$WT
            [int]$Age
            [string]$Team
            [int]$YOS
            [string]$PreDraftTeam
            [string]$DraftStatus
            [string]$Nationality
            [string]$SearchKey
            [string]$Rank
        }

        ### Configure modules

        @('PSParseHTML') | ForEach-Object {
            If (-not (Get-Module $_)) {
                Find-Module $_ | Install-Module -AllowClobber -Force
                Import-Module $_ -Force   
            }
        }
    }
    
    process {
        ### Scrape content
        $timestamp_start = Get-Date
        # $SearchKeyEx = @("'"," ",".",",","Jr","Sr","III","II") 
        $InvalidChars = @("'", ".", ",", "III", "II")
        [System.Collections.Generic.List[PSCustomObject]]$PlayerList = @()
        switch ($StoredQuery) {
            'PlayerData' {
                $uri = 'https://basketball.realgm.com/nba/players'
                $parsedHTMLresponse = ConvertFrom-Html -Url $uri -Engine AngleSharp
                $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("table").outerhtml) -ErrorAction SilentlyContinue
                if ($null -ne $convertedHTMLresponse) {
                    $convertedHTMLresponse | ForEach-Object {
                        $thisPlayer = New-Object PlayerCard
                        $thisPlayer.'Number' = $_.'#'
                        $thisPlayer.'Player' = $_.'Player'
                        ForEach ($char in $InvalidChars) { $thisPlayer.'Searchkey' = ($thisPlayer.'Player').Replace($char, '').Trim() }
                        $thisPlayer.'Pos' = $_.'Pos'
                        $thisPlayer.'HT' = $_.'HT'
                        $thisPlayer.'WT' = $_.'WT'
                        $thisPlayer.'Age' = $_.'Age'
                        $thisPlayer.'Team' = $_.'Current Team'
                        $thisPlayer.'YOS' = $_.'YOS'
                        $thisPlayer.'PreDraftTeam' = $_.'Pre-Draft Team'
                        $thisPlayer.'DraftStatus' = $_.'Draft Status'
                        $thisPlayer.'Nationality' = $_.'Nationality'
                        $PlayerList.Add($thisPlayer) 
                    }
                }
            }

            'SeasonData' {
                $uri = 'https://basketball.realgm.com/nba/stats/<year>/Totals/All/points/All/desc/Regular_Season'
                $uri = $uri.Replace("<year>", $Year)
                $looping = $true; $i = 1

                # While ($looping) {
                # Write-Progress -Activity "Downloading player data..." -Status "Scraping page $i...))" -PercentComplete $(Get-Random -Minimum 1 -Maximum 100) -CurrentOperation "Scraping Data"
                $parsedHTMLresponse = ConvertFrom-Html -Url $uri -Engine AngleSharp
                try {
                    $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("table").outerhtml) -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Verbose "Reached the end of valid HTML responses."
                }
                finally {
                    Remove-Variable parsedHTMLresponse -ErrorAction SilentlyContinue
                }
                    
                if ($null -ne $convertedHTMLresponse) {
                    $convertedHTMLresponse | ForEach-Object {
                        $thisPlayer = New-Object PlayerStats
                        $thisPlayer.'Number' = $_.'#'
                        $thisPlayer.'Player' = $_.'Player' 
                        ForEach ($char in $InvalidChars) { $thisPlayer.'Searchkey' = ($thisPlayer.'Player').Replace($char, '').Trim() }
                        $thisPlayer.'Team'  = $_.'Team' 
                        $thisPlayer.'GP'    = [int]$_.'GP' 
                        $thisPlayer.'MIN'   = [int]$_.'MIN' 
                        $thisPlayer.'PTS'   = [int]$_.'PTS' 
                        $thisPlayer.'FGM'   = [int]$_.'FGM' 
                        $thisPlayer.'FGA'   = [int]$_.'FGA' 
                        $thisPlayer.'FG'    = [int]$_.'FG%' 
                        $thisPlayer.'3PM'   = [int]$_.'3PM' 
                        $thisPlayer.'3PA'   = [int]$_.'3PA' 
                        $thisPlayer.'3P'    = [int]$_.'3P%'
                        $thisPlayer.'FTM'   = [int]$_.'FTM' 
                        $thisPlayer.'FTA'   = [int]$_.'FTA' 
                        $thisPlayer.'FT'    = [int]$_.'FT%' 
                        $thisPlayer.'ORB'   = [int]$_.'ORB' 
                        $thisPlayer.'DRB'   = [int]$_.'DRB' 
                        $thisPlayer.'REB'   = [int]$_.'REB' 
                        $thisPlayer.'AST'   = [int]$_.'AST' 
                        $thisPlayer.'STL'   = [int]$_.'STL' 
                        $thisPlayer.'BLK'   = [int]$_.'BLK' 
                        $thisPlayer.'TOV'   = [int]$_.'TOV' 
                        $thisPlayer.'PF'    = [int]$_.'PF'
                        $thisPlayer.'Score' = [int]$_.'PTS' + [int]$_.'REB' + [int]$_.'AST' - ([int]$_.'TOV' * 2)
                        $thisPlayer.'AVG'   = ([int]$_.'PTS' + [int]$_.'REB' + [int]$_.'AST' - ([int]$_.'TOV' * 2)) / $_.'GP'
                        $PlayerList.Add($thisPlayer)  
                    }
                    Remove-Variable convertedHTMLresponse
                    $i++
                }
                else {
                    $looping = $false
                }

                $playerList = $playerList | Sort-Object -Property Score -Descending
                (1..$playerList.count) | ForEach-Object {
                    $playerList[$_-1].Rank = [int]$_
                }

            }

            'PreseasonData' {
                $uri = 'https://basketball.realgm.com/nba/stats/<year>/Totals/All/points/All/desc/Preseason'
                $uri = $uri.Replace("<year>", $Year)
                $looping = $true; $i = 1
                
                #while ($looping) {
                # Write-Progress -Activity "Downloading player data..." -Status "Scraping page $i...))" -PercentComplete $(Get-Random -Minimum 1 -Maximum 100) -CurrentOperation "Scraping Data"
                $parsedHTMLresponse = ConvertFrom-Html -Url $uri -Engine AngleSharp
                try {
                    $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("table").outerhtml) -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Verbose "Reached the end of valid HTML responses."
                }
                finally {
                    Remove-Variable parsedHTMLresponse -ErrorAction SilentlyContinue
                }
                    
                if ($null -ne $convertedHTMLresponse) {
                    $convertedHTMLresponse | ForEach-Object {
                        $thisPlayer = New-Object PlayerStats
                        $thisPlayer.'Number' = $_.'#'
                        $thisPlayer.'Player' = $_.'Player' 
                        ForEach ($char in $InvalidChars) { $thisPlayer.'Searchkey' = ($thisPlayer.'Player').Replace($char, '').Trim() }
                        $thisPlayer.'Team' = $_.'Team' 
                        $thisPlayer.'GP' = $_.'GP' 
                        $thisPlayer.'MIN' = $_.'MIN' 
                        $thisPlayer.'PTS' = $_.'PTS' 
                        $thisPlayer.'FGM' = $_.'FGM' 
                        $thisPlayer.'FGA' = $_.'FGA' 
                        $thisPlayer.'FG' = $_.'FG%' 
                        $thisPlayer.'3PM' = $_.'3PM' 
                        $thisPlayer.'3PA' = $_.'3PA' 
                        $thisPlayer.'3P' = $_.'3P%'
                        $thisPlayer.'FTM' = $_.'FTM' 
                        $thisPlayer.'FTA' = $_.'FTA' 
                        $thisPlayer.'FT' = $_.'FT%' 
                        $thisPlayer.'ORB' = $_.'ORB' 
                        $thisPlayer.'DRB' = $_.'DRB' 
                        $thisPlayer.'REB' = $_.'REB' 
                        $thisPlayer.'AST' = $_.'AST' 
                        $thisPlayer.'STL' = $_.'STL' 
                        $thisPlayer.'BLK' = $_.'BLK' 
                        $thisPlayer.'TOV' = $_.'TOV' 
                        $thisPlayer.'PF' = $_.'PF'
                        $thisPlayer.'Score' = [int]$_.'PTS' + [int]$_.'REB' + [int]$_.'AST' - ([int]$_.'TOV' * 2)
                        $thisPlayer.'AVG' = ([int]$_.'PTS' + [int]$_.'REB' + [int]$_.'AST' - ([int]$_.'TOV' * 2)) / [int]$_.'GP'
                        $PlayerList.Add($thisPlayer) 
                    }
                    Remove-Variable convertedHTMLresponse
                    $i++
                }
                else {
                    $looping = $false
                }
                #}#
                
            }
        }
        $timestamp_end = Get-Date   
    }
    
    end {
        Write-Verbose "Web scrape operation duration (hh:mm:ss): $(New-TimeSpan -Start $timestamp_start -End $timestamp_end )"
        Return $PlayerList
    }
}


