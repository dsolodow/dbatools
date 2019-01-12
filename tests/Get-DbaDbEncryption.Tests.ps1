$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-ChildItem function:\Get-DbaDbEncryption).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'IncludeSystemDBs', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $knownParameters.Count
        }
    }
}
<#
    Integration test should appear below and are custom to the command you are writing.
    Read https://github.com/sqlcollaborative/dbatools/blob/development/contributing.md#tests
    for more guidence.
#>
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Test Retriving Certificate" {
        BeforeAll {
            $random = Get-Random
            $cert = "dbatoolsci_getcert$random"
            $password = ConvertTo-SecureString -String Get-Random -AsPlainText -Force
            New-DbaDbCertificate -SqlInstance $script:instance1 -Name $cert -password $password
        }
        AfterAll {
            Get-DbaDbCertificate -SqlInstance $script:instance1 -Certificate $cert | Remove-DbaDbCertificate -confirm:$false
        }
        $results = Get-DbaDbEncryption -SqlInstance $script:instance1
        It "Should find a certificate named $cert" {
            ($results.Name -match 'dbatoolsci').Count -gt 0 | Should Be $true
        }
    }
}