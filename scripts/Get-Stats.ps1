Function Get-Stats {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Uri
    )

    # scrape data
    $statsdownload = $null
    $loop = $true; $i = 1
    While ($loop -eq $true) {
        # retrieve web response
        $webResponse = Invoke-WebRequest -Method GET -Uri $($uri.Replace("<#>", $i))
        $targetTable = ($webresponse.ParsedHtml.getElementsByTagName('table') | Measure-Object).Count - 1
        $statsStaging = ConvertFrom-HtmlTable -WebRequest $webResponse -TableNumber $targetTable
        try {
            If ($statsStaging[0].'#' -gt 0) {
                $statsDownload += $statsStaging
                Write-Verbose "$(($statsDownload).Count) rows of data"
                $i++
            } Else {
                $loop = $false
            }
        } catch {
            $loop = $false
        }
    }
    Return $statsdownload
}