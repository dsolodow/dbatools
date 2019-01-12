$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $paramCount = 3
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\Invoke-DbatoolsRenameHelper).Parameters.Keys
        $knownParameters = 'InputObject', 'Encoding', 'EnableException'
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


Describe "$CommandName IntegrationTests" -Tag "IntegrationTests" {
    $content = @'
function Get-DbaStub {
    <#
        .SYNOPSIS
            is a stub

        .DESCRIPTION
            Using
    #>
    process {
        do this UseLastBackups
        then Find-SqlDuplicateIndex
        or Export-SqlUser -NoSystemLogins
        Write-Message -Level Verbose "stub"
    }
}
'@
    
    $wantedContent = @'
function Get-DbaStub {
    <#
        .SYNOPSIS
            is a stub

        .DESCRIPTION
            Using
    #>
    process {
        do this UseLastBackup
        then Find-DbaDuplicateIndex
        or Export-DbaUser -ExcludeSystemLogins
        Write-Message -Level Verbose "stub"
    }
}

'@
    
    Context "replacement actually works" {
        $temppath = Join-Path $TestDrive 'somefile2.ps1'
        [System.IO.File]::WriteAllText($temppath, $content)
        $results = $temppath | Invoke-DbatoolsRenameHelper
        $newcontent = [System.IO.File]::ReadAllText($temppath)
        
        It "returns 4 results" {
            $results.Count | Should -Be 4
        }

        foreach ($result in $results) {
            It "returns the expected results" {
                $result.Path | Should -Be $temppath
                $result.Pattern -in "Export-SqlUser", "Find-SqlDuplicateIndex", "UseLastBackups", "NoSystemLogins" | Should -Be $true
                $result.ReplacedWith -in "Export-DbaUser", "Find-DbaDuplicateIndex", "UseLastBackup", "ExcludeSystemLogins" | Should -Be $true
            }
        }

        It "returns expected specific results" {
            $result = $results | Where-Object Pattern -eq "Export-SqlUser"
            $result.ReplacedWith | Should -Be "Export-DbaUser"
        }
        
        It "should return exactly the format we want" {
            $newcontent | Should -Be $wantedContent
        }
    }
}