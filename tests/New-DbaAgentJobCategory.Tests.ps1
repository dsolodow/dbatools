$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 6
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\New-DbaAgentJobCategory).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Category', 'CategoryType', 'Force', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "New Agent Job Category is added properly" {

        It "Should have the right name and category type" {
            $results = New-DbaAgentJobCategory -SqlInstance $script:instance2 -Category CategoryTest1
            $results.Name | Should Be "CategoryTest1"
            $results.CategoryType | Should Be "LocalJob"
        }

        It "Should have the right name and category type" {
            $results = New-DbaAgentJobCategory -SqlInstance $script:instance2 -Category CategoryTest2 -CategoryType MultiServerJob
            $results.Name | Should Be "CategoryTest2"
            $results.CategoryType | Should Be "MultiServerJob"
        }

        It "Should actually for sure exist" {
            $newresults = Get-DbaAgentJobCategory -SqlInstance $script:instance2 -Category CategoryTest1, CategoryTest2
            $newresults[0].Name | Should Be "CategoryTest1"
            $newresults[0].CategoryType | Should Be "LocalJob"
            $newresults[1].Name | Should Be "CategoryTest2"
            $newresults[1].CategoryType | Should Be "MultiServerJob"
        }

        It "Should not write over existing job categories" {
            $results = New-DbaAgentJobCategory -SqlInstance $script:instance2 -Category CategoryTest1 -WarningAction SilentlyContinue -WarningVariable warn
            $warn -match "already exists" | Should Be $true
        }

        # Cleanup and ignore all output
        Remove-DbaAgentJobCategory -SqlInstance $script:instance2 -Category CategoryTest1, CategoryTest2 *> $null
    }
}