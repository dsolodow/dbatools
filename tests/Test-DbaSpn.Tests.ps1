$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 3
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem function:\Test-DbaSpn).Parameters.Keys
        $knownParameters = 'ComputerName', 'Credential', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    Context "gets spn information" {
        Mock Resolve-DbaNetworkName {
            [pscustomobject]@{
                InputName        = $env:COMPUTERNAME
                ComputerName     = $env:COMPUTERNAME
                IPAddress        = "127.0.0.1"
                DNSHostName      = $env:COMPUTERNAME
                DNSDomain        = $env:COMPUTERNAME
                Domain           = $env:COMPUTERNAME
                DNSHostEntry     = $env:COMPUTERNAME
                FQDN             = $env:COMPUTERNAME
                FullComputerName = $env:COMPUTERNAME
            }
        }
        $results = Test-DbaSpn -ComputerName $env:COMPUTERNAME -WarningAction SilentlyContinue
        It "returns some results" {
            $null -ne $results.RequiredSPN | Should -Be $true
        }
        foreach ($result in $results) {
            It "has the right properties" {
                $result.RequiredSPN -match 'MSSQLSvc' | Should -Be $true
                $result.Cluster -eq $false | Should -Be $true
                $result.TcpEnabled | Should -Be $true
                $result.IsSet -is [bool] | Should -Be $true
            }
        }
    }
}