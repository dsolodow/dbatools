function Test-DbaPowerPlan {
	<#
		.SYNOPSIS
			Checks the Power Plan settings for compliance with best practices, which recommend High Performance for SQL Server.

		.DESCRIPTION
			Checks the Power Plan settings on a computer against best practices recommendations. If one server is checked, only $true or $false is returned. If multiple servers are checked, each server's name and an IsBestPractice field are returned.

			Specify -Detailed for details.

			References:
			https://support.microsoft.com/en-us/kb/2207548
			http://www.sqlskills.com/blogs/glenn/windows-power-plan-effects-on-newer-intel-processors/

		.PARAMETER ComputerName
			The server(s) to check Power Plan settings on.

		.PARAMETER Credential
			Specifies a PSCredential object to use in authenticating to the server(s), instead of the current user account.

		.PARAMETER CustomPowerPlan
			If your organization uses a custom power plan that's considered best practice, specify it here.

		.PARAMETER Detailed
			If this switch is enabled, a detailed list will be returned. This parameter will be removed in 1.0.

		.PARAMETER EnableException 
			By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
			This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
			Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
			
		.NOTES
			Requires: WMI access to servers

			dbatools PowerShell module (https://dbatools.io, clemaire@gmail.com)
			Copyright (C) 2016 Chrissy LeMaire
			License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

		.LINK
			https://dbatools.io/Test-DbaPowerPlan

		.EXAMPLE
			Test-DbaPowerPlan -ComputerName sqlserver2014a

			Checks the Power Plan settings for sqlserver2014a and indicates whether or not it complies with best practices.

		.EXAMPLE
			Test-DbaPowerPlan -ComputerName sqlserver2014a -CustomPowerPlan 'Maximum Performance'

			Checks the Power Plan settings for sqlserver2014a and indicates whether or not it is set to the custom plan "Maximum Performance".

		.EXAMPLE
			Test-DbaPowerPlan -ComputerName sqlserver2014a -Detailed

			Returns detailed information about the Power Plans on sqlserver2014a.

	#>
	param (
		[parameter(ValueFromPipeline = $true)]
		[Alias("ServerInstance", "SqlServer", "SqlInstance")]
		[string[]]$ComputerName = $env:COMPUTERNAME,
		[PSCredential]$Credential,
		[string]$CustomPowerPlan,
		[switch]$Detailed,
		[switch][Alias('Silent')]$EnableException
	)
	
	begin {
		if ($Detailed) {
			Write-Message -Level Warning -Message "Detailed is deprecated and will be removed in dbatools 1.0"
		}
		
		$bpPowerPlan = [PSCustomObject]@{
			InstanceID  = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
			ElementName = $null
		}
		
		$sessionoption = New-CimSessionOption -Protocol DCom
	}
	
	process {
		foreach ($computer in $ComputerName) {
			$Server = Resolve-DbaNetworkName -ComputerName $computer -Credential $credential
			
			$Computer = $server.ComputerName
			
			if (!$Computer) {
				Stop-Function -Message "Couldn't resolve hostname. Skipping." -Continue
			}
			
			Write-Message -Level Verbose -Message "Creating CimSession on $computer over WSMan."
			
			if (!$Credential) {
				$cimsession = New-CimSession -ComputerName $Computer -ErrorAction SilentlyContinue
			}
			else {
				$cimsession = New-CimSession -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $Credential
			}
			
			if ($null -eq $cimsession.id) {
				Write-Message -Level Verbose -Message "Creating CimSession on $computer over WSMan failed. Creating CimSession on $computer over DCOM."
				
				if (!$Credential) {
					$cimsession = New-CimSession -ComputerName $Computer -SessionOption $sessionoption -ErrorAction SilentlyContinue -Credential $Credential
				}
				else {
					$cimsession = New-CimSession -ComputerName $Computer -SessionOption $sessionoption -ErrorAction SilentlyContinue
				}
			}
			
			if ($null -eq $cimsession.id) {
				Stop-Function -Message "Can't create CimSession on $computer." -Target $Computer
			}
			
			Write-Message -Level Verbose -Message "Getting Power Plan information from $Computer."
			
			try {
				$powerplans = Get-CimInstance -CimSession $cimsession -classname Win32_PowerPlan -Namespace "root\cimv2\power" -ErrorAction Stop | Select-Object ElementName, InstanceID, IsActive
			}
			catch {
				if ($_.Exception -match "namespace") {
					Stop-Function -Message "Can't get Power Plan Info for $Computer. Unsupported operating system." -Continue -InnerErrorRecord $_ -Target $Computer
				}
				else {
					Stop-Function -Message "Can't get Power Plan Info for $Computer. Check logs for more details." -Continue -InnerErrorRecord $_ -Target $Computer
				}
			}
			
			$powerplan = $powerplans | Where-Object { $_.IsActive -eq 'True' } | Select-Object ElementName, InstanceID
			$powerplan.InstanceID = $powerplan.InstanceID.Split('{')[1].Split('}')[0]
			
			if ($CustomPowerPlan.Length -gt 0) {
				$bpPowerPlan.ElementName = $CustomPowerPlan
				$bpPowerPlan.InstanceID = $($powerplans | Where-Object { $_.ElementName -eq $CustomPowerPlan }).InstanceID
			}
			else {
				$bpPowerPlan.ElementName = $($powerplans | Where-Object { $_.InstanceID.Split('{')[1].Split('}')[0] -eq $bpPowerPlan.InstanceID }).ElementName
				if ($null -eq $bpPowerplan.ElementName) {
					$bpPowerPlan.ElementName = "You do not have the high performance plan installed on this machine."
				}
			}
			
			Write-Message -Level Verbose -Message "Recommended GUID is $($bpPowerPlan.InstanceID) and you have $($powerplan.InstanceID)."
			
			if ($null -eq $powerplan.InstanceID) {
				$powerplan.ElementName = "Unknown"
			}
			
			if ($powerplan.InstanceID -eq $bpPowerPlan.InstanceID) {
				$IsBestPractice = $true
			}
			else {
				$IsBestPractice = $false
			}
			
			[PSCustomObject]@{
				Server               = $computer
				ActivePowerPlan      = $powerplan.ElementName
				RecommendedPowerPlan = $bpPowerPlan.ElementName
				IsBestPractice       = $IsBestPractice
			}
		}
	}
}