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
            [int]$GP
            [double]$MIN
            [int]$PTS
            [int]$FGM
            [int]$FGA
            [double]$FG
            [int]$3PM
            [int]$3PA
            [double]$3P
            [int]$FTM
            [int]$FTA
            [double]$FT
            [int]$ORB
            [int]$DRB
            [int]$REB
            [int]$AST
            [int]$STL
            [int]$BLK
            [int]$TOV
            [int]$PF
            [int]$Score
            [int]$AVG
            [string]$SearchKey
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
        $InvalidChars = @("'", ".", ",", "III", "II", "Jr", "Sr")
        [System.Collections.Generic.List[PSCustomObject]]$PlayerList = @()
        switch ($StoredQuery) {
            'PlayerData' {
                $uri = 'https://basketball.realgm.com/nba/players'
                $parsedHTMLresponse = ConvertFrom-Html -Url $uri -Engine AngleSharp
                $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("tablesaw").outerhtml) -ErrorAction SilentlyContinue
                if ($null -ne $convertedHTMLresponse) {
                    $convertedHTMLresponse | ForEach-Object {
                        $thisPlayer = New-Object PlayerCard
                        $thisPlayer.'Number' = $_.'#'
                        $thisPlayer.'Player' = $_.'Player'
                        ForEach ($char in $InvalidChars) { $thisPlayer.'Player' = ($thisPlayer.'Player').Replace($char, '').Trim() }
                        $thisPlayer.'Pos' = $_.'Pos'
                        $thisPlayer.'HT' = $_.'HT'
                        $thisPlayer.'WT' = $_.'WT'
                        $thisPlayer.'Age' = $_.'Age'
                        $thisPlayer.'Team' = $_.'CurrentTeam'
                        $thisPlayer.'YOS' = $_.'YOS'
                        $thisPlayer.'PreDraftTeam' = $_.'PreDraftTeam'
                        $thisPlayer.'DraftStatus' = $_.'DraftStatus'
                        $thisPlayer.'Nationality' = $_.'Nationality'
                        $PlayerList.Add($thisPlayer) 
                    }
                }
            }

            'SeasonData' {
                $uri = 'https://basketball.realgm.com/nba/stats/<year>/Totals/All/points/All/desc/<#>/Regular_Season'
                $uri = $uri.Replace("<year>", $Year)
                $looping = $true; $i = 1

                While ($looping) {
                    Write-Progress -Activity "Downloading player data..." -Status "Scraping page $i...))" -PercentComplete $(Get-Random -Minimum 1 -Maximum 100) -CurrentOperation "Scraping Data"
                    $parsedHTMLresponse = ConvertFrom-Html -Url $($uri.Replace("<#>", $i)) -Engine AngleSharp
                    try {
                        $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("tablesaw compact").outerhtml) -ErrorAction SilentlyContinue
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
                            ForEach ($char in $InvalidChars) { $thisPlayer.'Player' = ($thisPlayer.'Player').Replace($char, '').Trim() }
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
                            $thisPlayer.'AVG' = ([int]$_.'PTS' + [int]$_.'REB' + [int]$_.'AST' - ([int]$_.'TOV' * 2)) / $_.'GP'
                            $PlayerList.Add($thisPlayer)  
                        }
                        Remove-Variable convertedHTMLresponse
                        $i++
                    }
                    else {
                        $looping = $false
                    }
                }
                
            }

            'PreseasonData' {
                $uri = 'https://basketball.realgm.com/nba/stats/<year>/Totals/All/points/All/desc/<#>/Preseason'
                $uri = $uri.Replace("<year>", $Year)
                $looping = $true; $i = 1
                
                while ($looping) {
                    Write-Progress -Activity "Downloading player data..." -Status "Scraping page $i...))" -PercentComplete $(Get-Random -Minimum 1 -Maximum 100) -CurrentOperation "Scraping Data"
                    $parsedHTMLresponse = ConvertFrom-Html -Url $($uri.Replace("<#>", $i)) -Engine AngleSharp
                    try {
                        $convertedHTMLresponse = ConvertFrom-HtmlTable -Content ($parsedHTMLresponse.GetElementsByClassName("tablesaw compact").outerhtml) -ErrorAction SilentlyContinue
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
                            ForEach ($char in $InvalidChars) { $thisPlayer.'Player' = ($thisPlayer.'Player').Replace($char, '').Trim() }
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
                }
                
            }
        }
        $timestamp_end = Get-Date   
    }
    
    end {
        Write-Verbose "Web scrape operation duration (hh:mm:ss): $(New-TimeSpan -Start $timestamp_start -End $timestamp_end )"
        Return $PlayerList
    }
}


