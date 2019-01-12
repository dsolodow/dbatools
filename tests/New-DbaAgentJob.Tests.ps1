$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 19
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\New-DbaAgentJob).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Job', 'Schedule', 'ScheduleId', 'Disabled', 'Description', 'StartStepId', 'Category', 'OwnerLogin', 'EventLogLevel', 'EmailLevel', 'PageLevel', 'EmailOperator', 'NetsendOperator', 'PageOperator', 'DeleteLevel', 'Force', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "New Agent JOb is added properly" {

        It "Should have the right name and description" {
            $results = New-DbaAgentJob -SqlInstance $script:instance2 -Job "Job One" -Description "Just another job"
            $results.Name | Should Be "Job One"
            $results.Description | Should Be "Just another job"
        }

        It "Should actually for sure exist" {
            $newresults = Get-DbaAgentJob -SqlInstance $script:instance2 -Job "Job One"
            $newresults.Name | Should Be "Job One"
            $newresults.Description | Should Be "Just another job"
        }

        It "Should not write over existing jobs" {
            $results = New-DbaAgentJob -SqlInstance $script:instance2 -Job "Job One" -Description "Just another job" -WarningAction SilentlyContinue -WarningVariable warn
            $warn -match "already exists" | Should Be $true
        }

        # Cleanup and ignore all output
        Remove-DbaAgentJob -SqlInstance $script:instance2 -Job "Job One" *> $null
    }
}