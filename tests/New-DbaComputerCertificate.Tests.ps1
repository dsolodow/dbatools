$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 14
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\New-DbaComputerCertificate).Parameters.Keys
        $knownParameters = 'ComputerName', 'Credential', 'CaServer', 'CaName', 'ClusterInstanceName', 'SecurePassword', 'FriendlyName', 'CertificateTemplate', 'KeyLength', 'Store', 'Folder', 'Dns', 'SelfSigned', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

if (-not $env:appveyor) {
    Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
        Context "Can generate a new certificate" {
            BeforeAll {
                $cert = New-DbaComputerCertificate -SelfSigned -EnableException
            }
            AfterAll {
                Remove-DbaComputerCertificate -Thumbprint $cert.Thumbprint -Confirm:$false
            }
            It "returns the right EnhancedKeyUsageList" {
                "$($cert.EnhancedKeyUsageList)" -match '1\.3\.6\.1\.5\.5\.7\.3\.1' | Should Be $true
            }
            It "returns the right FriendlyName" {
                "$($cert.FriendlyName)" -match 'SQL Server' | Should Be $true
            }
        }
    }
}