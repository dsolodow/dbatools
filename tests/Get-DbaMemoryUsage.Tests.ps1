$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Get-DbaMemoryUsage).Parameters.Keys
        $knownParameters = 'ComputerName', 'Credential', 'EnableException'
        $paramCount = $knownParameters.Count
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}
<#
    Integration test should appear below and are custom to the command you are writing.
    Read https://github.com/sqlcollaborative/dbatools/blob/development/contributing.md#tests
    for more guidence.
#>
Describe "Get-DbaMemoryUsage Integration Test" -Tag "IntegrationTests" {
    Context "Command actually works" {
        $results = Get-DbaMemoryUsage -ComputerName $script:instance1

        It "returns results" {
            $results.Count -gt 0 | Should Be $true
        }
        It "has the correct properties" {
            $result = $results[0]
            $ExpectedProps = 'ComputerName,SqlInstance,CounterInstance,Counter,Pages,Memory'.Split(',')
            ($result.PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
        }

        $resultsSimple = Get-DbaMemoryUsage -ComputerName $script:instance1
        It "returns results" {
            $resultsSimple.Count -gt 0 | Should Be $true
        }
    }
}