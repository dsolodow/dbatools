$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 11
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\New-DbaDbCertificate).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Name', 'Database', 'Subject', 'StartDate', 'ExpirationDate', 'ActiveForServiceBrokerDialog', 'SecurePassword', 'InputObject', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "Can create a database certificate" {
        BeforeAll {
            if (-not (Get-DbaDbMasterKey -SqlInstance $script:instance1 -Database master)) {
                $masterkey = New-DbaDbMasterKey -SqlInstance $script:instance1 -Database master -Password $(ConvertTo-SecureString -String "GoodPass1234!" -AsPlainText -Force) -Confirm:$false
            }

            $tempdbmasterkey = New-DbaDbMasterKey -SqlInstance $script:instance1 -Database tempdb -Password $(ConvertTo-SecureString -String "GoodPass1234!" -AsPlainText -Force) -Confirm:$false
            $certificateName1 = "Cert_$(Get-random)"
            $certificateName2 = "Cert_$(Get-random)"
        }
        AfterAll {
            if ($tempdbmasterkey) { $tempdbmasterkey | Remove-DbaDbMasterKey -Confirm:$false }
            if ($masterKey) { $masterkey | Remove-DbaDbMasterKey -Confirm:$false }
        }

        $cert1 = New-DbaDbCertificate -SqlInstance $script:instance1 -Name $certificateName1 -Confirm:$false
        It "Successfully creates a new database certificate in default, master database" {
            "$($cert1.name)" -match $certificateName1 | Should Be $true
        }

        $cert2 = New-DbaDbCertificate -SqlInstance $script:instance1 -Name $certificateName2 -Database tempdb -Confirm:$false
        It "Successfully creates a new database certificate in the tempdb database" {
            "$($cert2.Database)" -match "tempdb" | Should Be $true
        }

        $null = $cert1 | Remove-DbaDbCertificate -Confirm:$false
        $null = $cert2 | Remove-DbaDbCertificate -Confirm:$false
    }
}