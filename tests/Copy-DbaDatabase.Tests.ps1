﻿$commandname = $MyInvocation.MyCommand.Name.Replace(".ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
	BeforeAll {
		$BackupLocation = "$script:appeyorlabrepo\singlerestore\singlerestore.bak"
		$NetworkPath = "C:\temp"
		$DBNameBackupRestore = "dbatoolsci_singlerestore"
		$DBNameAttachDetach = "dbatoolsci_detachattach"
		# cleanup
		foreach ($instance in $Instances) {
			Remove-DbaDatabase -Confirm:$false -SqlInstance $instance -Database $DBNameBackupRestore,$DBNameAttachDetach
		}
	}
	AfterAll {
		foreach ($instance in $Instances) {
			Remove-DbaDatabase -Confirm:$false -SqlInstance $instance -Database $DBNameBackupRestore,$DBNameAttachDetach
		}
	}
	
	
	# Restore and set owner for Single Restore
	$null = Restore-DbaDatabase -SqlInstance $script:instance1 -Path $script:appeyorlabrepo\singlerestore\singlerestore.bak -WithReplace -DatabaseName $DBNameBackupRestore
	Set-DbaDatabaseOwner -SqlInstance $script:instance1 -Database $DBNameBackupRestore -TargetLogin sa
	
	Context "Restores database with the same properties." {
		It "Should copy a database and retain its name, recovery model, and status." {
			
			Copy-DbaDatabase -Source $script:instance1 -Destination $script:instance2 -Database $DBNameBackupRestore -BackupRestore -NetworkShare $NetworkPath
			
			$db1 = Get-DbaDatabase -SqlInstance $script:instance1 -Database $DBNameBackupRestore
			$db1 | Should Not BeNullOrEmpty
			$db2 = Get-DbaDatabase -SqlInstance $script:instance2 -Database $DBNameBackupRestore
			$db2 | Should Not BeNullOrEmpty
			
			# Compare its valuable.
			$db1.Name | Should Be $db2.Name
			$db1.RecoveryModel | Should Be $db2.RecoveryModel
			$db1.Status | Should be $db2.Status
		}
	}
	
	Context "Doesn't write over existing databases" {
		It "Should say skipped" {
			$result = Copy-DbaDatabase -Source $script:instance1 -Destination $script:instance2 -Database $DBNameBackupRestore -BackupRestore -NetworkShare $NetworkPath
			$result.Status | Should be "Skipped"
			$result.Notes | Should be "Already exists"
		}
	}
	
	foreach ($instance in $Instances) {
		Remove-DbaDatabase -Confirm:$false -SqlInstance $instance -Database $DBNameBackupRestore
	}
	
	Context "Detach, copies and attaches database successfully." {
		It "Should be success" {
			$null = Restore-DbaDatabase -SqlInstance $script:instance1 -Path $script:appeyorlabrepo\detachattach\detachattach.bak -WithReplace -DatabaseName $DBNameAttachDetach
			$results = Copy-DbaDatabase -Source $script:instance1 -Destination $script:instance2 -Database $DBNameAttachDetach -DetachAttach -Reattach -Force -WarningAction SilentlyContinue
			$results.Status | Should Be "Successful"
		}
	}
	
	Context "Database with the same properties." {
		It "should not be null" {
			
			$db1 = (Connect-DbaInstance -SqlInstance localhost).Databases[$DBNameAttachDetach]
			$db2 = (Connect-DbaInstance -SqlInstance localhost\sql2016).Databases[$DBNameAttachDetach]
			
			$db1 | Should Not Be $null
			$db2 | Should Not Be $null
			
			$db1.Name | Should Be $DBNameAttachDetach
			$db2.Name | Should Be $DBNameAttachDetach
		}
	<#
		It "Name, recovery model, and status should match" {
			# This is crazy
			(Connect-DbaInstance -SqlInstance localhost).Databases['detachattach'].Name | Should Be (Connect-DbaInstance -SqlInstance localhost\sql2016).Databases['detachattach'].Name
			(Connect-DbaInstance -SqlInstance localhost).Databases['detachattach'].Tables.Count | Should Be (Connect-DbaInstance -SqlInstance localhost\sql2016).Databases['detachattach'].Tables.Count
			(Connect-DbaInstance -SqlInstance localhost).Databases['detachattach'].Status | Should Be (Connect-DbaInstance -SqlInstance localhost\sql2016).Databases['detachattach'].Status
			
		}
	}
	
	Context "Clean up" {
		foreach ($instance in $instances) {
			Get-DbaDatabase -SqlInstance $instance -NoSystemDb | Remove-DbaDatabase -Confirm:$false
		}
		#>
	}
	
}