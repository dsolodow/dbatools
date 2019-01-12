$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 4
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Test-DbaMaxDop).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Detailed', 'EnableException'
        It "Should contain our specific parameters" {
            ((Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        Get-DbaProcess -SqlInstance $script:instance2 -Program 'dbatools PowerShell module - dbatools.io' | Stop-DbaProcess -WarningAction SilentlyContinue
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $db1 = "dbatoolsci_testMaxDop"
        $server.Query("CREATE DATABASE dbatoolsci_testMaxDop")
        $needed = Get-DbaDatabase -SqlInstance $script:instance2 -Database $db1
        $setupright = $true
        if (-not $needed) {
            $setupright = $false
        }
    }
    AfterAll {
        Get-DbaDatabase -SqlInstance $script:instance2 -Database $db1 | Remove-DbaDatabase -Confirm:$false
    }

    # Just not messin with this in appveyor
    if ($setupright) {
        Context "Command works on SQL Server 2016 or higher instances" {
            $results = Test-DbaMaxDop -SqlInstance $script:instance2

            It "Should have correct properties" {
                $ExpectedProps = 'ComputerName,InstanceName,SqlInstance,Database,DatabaseMaxDop,CurrentInstanceMaxDop,RecommendedMaxDop,Notes'.Split(',')
                foreach ($result in $results) {
                    ($result.PSStandardMembers.DefaultDIsplayPropertySet.ReferencedPropertyNames | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
                }
            }

            It "Should have only one result for database name of dbatoolsci_testMaxDop" {
                @($results | Where-Object Database -eq dbatoolsci_testMaxDop).Count | Should Be 1
            }
        }
    }
}