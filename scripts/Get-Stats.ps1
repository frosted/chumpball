Function Get-Stats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Uri
    )

    Install-Module -Name PSParseHTML

    # $loop = $true; $x = 1
    # While ($loop -eq $true) {
    # retrieve web response
    $webResponse = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $htmlDom = $webResponse.Content | ConvertFrom-Html
    # $targetTable = ($webresponse.ParsedHtml.getElementsByTagName('table') | Measure-Object).Count - 1

    if ($htmlDom.SelectNodes('//table').count -gt 0) {
        $table = $htmlDom.SelectNodes('//table')[0]
        $headers = $table.SelectNodes('.//tr[1]/th') | ForEach-Object { $_.InnerText.Trim() }
        $rows = $table.SelectNodes('.//tr[position()>1]')
        $playerStats = @()

        foreach ($row in $rows) {
            $cells = $row.SelectNodes('.//td')
            $rowData = @{}

            for ($i = 0; $i -lt $headers.Count; $i++) {
                $rowData[$headers[$i]] = $cells[$i].InnerText.Trim()
            }

            $playerStats += New-Object PSObject -Property $rowData
        }
    }
    else {
        $loop = $false
    }
    <#
        $statsStaging = ConvertFrom-HtmlTable -WebRequest $webResponse -TableNumber $targetTable
        try {
            If ($statsStaging[0].'#' -gt 0) {
                $statsDownload += $statsStaging
                Write-Verbose "$(($statsDownload).Count) rows of data"
                $i++
            }
            Else {
                $loop = $false
            }
        }
        catch {
            $loop = $false
        }#>
    # }
    Return $playerStats
}