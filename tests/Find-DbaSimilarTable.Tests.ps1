$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 10
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Find-DbaSimilarTable).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'SchemaName', 'TableName', 'ExcludeViews', 'IncludeSystemDatabases', 'MatchPercentThreshold', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "Testing if similar tables are discovered" {
        BeforeAll {
            $db = Get-DbaDatabase -SqlInstance $script:instance1 -Database tempdb
            $db.Query("CREATE TABLE dbatoolsci_table1 (id int identity, fname varchar(20), lname char(5), lol bigint, whatever datetime)")
            $db.Query("CREATE TABLE dbatoolsci_table2 (id int identity, fname varchar(20), lname char(5), lol bigint, whatever datetime)")
        }
        AfterAll {
            $db.Query("DROP TABLE dbatoolsci_table1")
            $db.Query("DROP TABLE dbatoolsci_table2")
        }

        $results = Find-DbaSimilarTable -SqlInstance $script:instance1 -Database tempdb | Where-Object Table -Match dbatoolsci

        It "returns at least two rows" { # not an exact count because who knows
            $results.Count -ge 2 | Should Be $true
        }

        foreach ($result in $results) {
            It "matches 100% for the test tables" {
                $result.MatchPercent -eq 100 | Should Be $true
            }
        }
    }
}