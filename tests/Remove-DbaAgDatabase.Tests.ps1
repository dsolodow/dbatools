$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$commandname Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 6
        <#
            Get commands, Default count = 11
            Commands with SupportShouldProcess = 13
               #>
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\Remove-DbaAvailabilityGroup).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'AvailabilityGroup', 'AllAvailabilityGroups', 'InputObject', 'EnableException'
        it "Should contain our specific parameters" {
            ((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $paramCount
        }
        it "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$commandname Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $null = Get-DbaProcess -SqlInstance $script:instance3 -Program 'dbatools PowerShell module - dbatools.io' | Stop-DbaProcess -WarningAction SilentlyContinue
        $server = Connect-DbaInstance -SqlInstance $script:instance3
        $agname = "dbatoolsci_removeagdb_agroup"
        $dbname = "dbatoolsci_removeagdb_agroupdb"
        $server.Query("create database $dbname")
        $null = Get-DbaDatabase -SqlInstance $script:instance3 -Database $dbname | Backup-DbaDatabase
        $null = Get-DbaDatabase -SqlInstance $script:instance3 -Database $dbname | Backup-DbaDatabase -Type Log
        $ag = New-DbaAvailabilityGroup -Primary $script:instance3 -Name $agname -ClusterType None -FailoverMode Manual -Database $dbname -Confirm:$false -Certificate dbatoolsci_AGCert -UseLastBackup
    }
    AfterAll {
        $null = Remove-DbaAvailabilityGroup -SqlInstance $server -AvailabilityGroup $agname -Confirm:$false
        $null = Remove-DbaDatabase -SqlInstance $server -Database $dbname -Confirm:$false
    }
    Context "removes ag db" {
        It "returns removed results" {
            $results = Remove-DbaAgDatabase -SqlInstance $script:instance3 -Database $dbname -Confirm:$false
            $results.AvailabilityGroup | Should -Be $agname
            $results.Database | Should -Be $dbname
            $results.Status | Should -Be 'Removed'
        }

        It "really removed the db from the ag" {
            $results = Get-DbaAvailabilityGroup -SqlInstance $script:instance3 -AvailabilityGroup $agname
            $results.AvailabilityGroup | Should -Be $agname
            $results.AvailabilityDatabases.Name | Should -Not -Contain $dbname
        }
    }
} #$script:instance2 for appveyor