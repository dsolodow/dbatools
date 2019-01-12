$commandname = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 5
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaSpConfigure).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Name', 'ExcludeName', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Get configuration" {
        $server = Connect-DbaInstance -SqlInstance $script:instance1
        $configs = $server.Query("sp_configure")
        $remotequerytimeout = $configs | Where-Object name -match 'remote query timeout'

        It "returns equal to results of the straight T-SQL query" {
            $results = Get-DbaSpConfigure -SqlInstance $script:instance1
            $results.count -eq $configs.count
        }

        It "returns two results" {
            $results = Get-DbaSpConfigure -SqlInstance $script:instance1 -Name RemoteQueryTimeout, AllowUpdates
            $results.Count | Should Be 2
        }

        It "returns two results less than all data" {
            $results = Get-DbaSpConfigure -SqlInstance $script:instance1 -ExcludeName "remote query timeout (s)", AllowUpdates
            $results.Count -eq $configs.count - 2
        }

        It "matches the output of sp_configure " {
            $results = Get-DbaSpConfigure -SqlInstance $script:instance1 -Name RemoteQueryTimeout
            $results.ConfiguredValue -eq $remotequerytimeout.config_value | Should Be $true
            $results.RunningValue -eq $remotequerytimeout.run_value | Should Be $true
        }
    }
}