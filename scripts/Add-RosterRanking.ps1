Function Add-RosterRanking {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]
        $RosterInput
    )
    
    begin {
        Write-Verbose "Ranking $(($RosterInput).count) players and $(($RosterInput | Select-Object -Unique Owner | Measure-Object | Select-Object -ExpandProperty Count)) teams."
    }
    
    process {
        # add team rankings
        $RosterInput = $RosterInput | Group-Object -Property Owner | ForEach-Object {
            $rank = 0
            $_.Group | Sort-Object FV -Descending | Select-Object *, @{ 
                Name = 'TeamRk'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank } 
            }
        }

        # add positional rankings
        $RosterInput = $RosterInput | Group-Object -Property Owner, Pos | ForEach-Object {
            $rank = 0
            $_.Group | Sort-Object TeamRk | Select-Object *, @{ 
                Name = 'PosRk'; Expression = { Set-Variable -Scope 1 rank ($rank + 1); $rank } 
            }
        }

        $rosterOutput = [System.Collections.Generic.List[object]]::new()
        $RosterInput | Where-Object { ($_.Pos -eq 'C' -and $_.PosRk -eq 1) -or ($_.Pos -eq 'F' -and $_.PosRk -le 2) -or ($_.Pos -eq 'G' -and $_.PosRk -le 2) } | Select-Object *, @{Name = 'Assignment'; Expression = { 'TeamA' } } | ForEach-Object { Write-Verbose "$($_.Name) assigned to $($_.Owner)'s $($_.Assignment)"; $rosterOutput.Add($_) }
        $RosterInput | Where-Object { ($_.Pos -eq 'C' -and $_.PosRk -eq 2) -or ($_.Pos -eq 'F' -and $_.PosRk -gt 2 -and $_.PosRk -le 4) -or ($_.Pos -eq 'G' -and $_.PosRk -gt 2 -and $_.PosRk -le 4) } | Select-Object *, @{Name = 'Assignment'; Expression = { 'TeamB' } } | ForEach-Object { Write-Verbose "$($_.Name) assigned to $($_.Owner)'s $($_.Assignment)"; $rosterOutput.Add($_) }
        $RosterInput | Where-Object { $_.Name -notin $RosterOutput.Name } | Select-Object *, @{Name = 'Assignment'; Expression = { 'Bench' } } | ForEach-Object { Write-Verbose "$($_.Name) assigned to $($_.Owner)'s $($_.Assignment)"; $rosterOutput.Add($_) }
    }
    
    end {
        Return $rosterOutput
    }
}