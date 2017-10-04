Function Stop-DbaSqlService {
<#
	.SYNOPSIS
	Stops SQL Server services on a computer. 

	.DESCRIPTION
	Stops the SQL Server related services on one or more computers. Will follow SQL Server service dependencies.

	Requires Local Admin rights on destination computer(s).

	.PARAMETER ComputerName
	The SQL Server (or server in general) that you're connecting to. This command handles named instances.

	.PARAMETER InstanceName
	Only affects services that belong to the specific instances.

	.PARAMETER Credential
	Credential object used to connect to the computer as a different user.

	.PARAMETER Type
	Use -Type to collect only services of the desired SqlServiceType.
	Can be one of the following: "Agent","Browser","Engine","FullText","SSAS","SSIS","SSRS"

	.PARAMETER Timeout
	How long to wait for the start/stop request completion before moving on. Specify 0 to wait indefinitely.

	.PARAMETER ServiceCollection
	A collection of services from Get-DbaSqlService

	.PARAMETER Force
	Use this switch to stop dependent services before proceeding with the specified service

	.PARAMETER Silent
	Use this switch to disable any kind of verbose messages

	.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet is not run.

	.PARAMETER Confirm
	Prompts you for confirmation before running the cmdlet.

	.PARAMETER Force
	Will stop dependent SQL Server agents when stopping Engine services.

	.NOTES
	Author: Kirill Kravtsov( @nvarscar )

	dbatools PowerShell module (https://dbatools.io)
	Copyright (C) 2017 Chrissy LeMaire
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

	.LINK
	https://dbatools.io/Stop-DbaSqlService

	.EXAMPLE
	Stop-DbaSqlService -ComputerName sqlserver2014a

	Stops the SQL Server related services on computer sqlserver2014a.

	.EXAMPLE   
	'sql1','sql2','sql3'| Get-DbaSqlService | Stop-DbaSqlService

	Gets the SQL Server related services on computers sql1, sql2 and sql3 and stops them.

	.EXAMPLE
	Stop-DbaSqlService -ComputerName sql1,sql2 -Instance MSSQLSERVER

	Stops the SQL Server services related to the default instance MSSQLSERVER on computers sql1 and sql2.

	.EXAMPLE
	Stop-DbaSqlService -ComputerName $MyServers -Type SSRS

	Stops the SQL Server related services of type "SSRS" (Reporting Services) on computers in the variable MyServers.

	.EXAMPLE
	Stop-DbaSqlService -ComputerName sql1 -Type Engine -Force

	Stops SQL Server database engine services on sql1 forcing dependent SQL Server Agent services to stop as well.

#>
	[CmdletBinding(DefaultParameterSetName = "Server", SupportsShouldProcess = $true)]
	Param (
		[Parameter(ParameterSetName = "Server", Position = 1)]
		[Alias("cn", "host", "Server")]
		[DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
		[Alias("Instance")]
		[string[]]$InstanceName,
		[ValidateSet("Agent", "Browser", "Engine", "FullText", "SSAS", "SSIS", "SSRS")]
		[string[]]$Type,
		[parameter(ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Service")]
		[object[]]$ServiceCollection,
		[int]$Timeout = 30,
		[PSCredential]$Credential,
		[switch]$Force,
		[switch]$Silent
	)
	begin {
		$processArray = @()
		if ($PsCmdlet.ParameterSetName -eq "Server") {
			$serviceParams = @{ ComputerName = $ComputerName }
			if ($InstanceName) { $serviceParams.InstanceName = $InstanceName }
			if ($Type) { $serviceParams.Type = $Type }
			if ($Credential) { $serviceParams.Credential = $Credential }
			if ($Silent) { $serviceParams.Silent = $Silent }
			$serviceCollection = Get-DbaSqlService @serviceParams
		}
	}
	process {
		#Get all the objects from the pipeline before proceeding
		$processArray += $serviceCollection
	}
	end {
		$processArray = [array]($processArray | Where-Object { (!$InstanceName -or $_.InstanceName -in $InstanceName) -and (!$Type -or $_.ServiceType -in $Type) })
		foreach ($service in $processArray) {
			if ($Force -and $service.ServiceType -eq 'Engine' -and !($processArray | Where-Object { $_.ServiceType -eq 'Agent' -and $_.InstanceName -eq $service.InstanceName -and $_.ComputerName -eq $service.ComputerName })) {
				#Construct parameters to call Get-DbaSqlService
				$serviceParams = @{ 
					ComputerName = $service.ComputerName 
					InstanceName = $service.InstanceName
					Type         = 'Agent'
				}
				if ($Credential) { $serviceParams.Credential = $Credential }
				if ($Silent) { $serviceParams.Silent = $Silent }
				$processArray += @(Get-DbaSqlService @serviceParams)
			}
		}
		if ($processArray) {
			Update-ServiceStatus -ServiceCollection $processArray -Action 'stop' -Timeout $Timeout -Silent $Silent
		}
		else { Stop-Function -Silent $Silent -Message "No SQL Server services found with current parameters." -Category ObjectNotFound }
	}
}