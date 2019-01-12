# Write-DbaDataTable: Settings for ConvertTo-DbaDataTable
Set-DbatoolsConfig -FullName 'commands.write-dbadatatable.timespantype' -Value 'TotalMilliseconds' -Initialize -Validation string -Description "When passing random objects at Write-DbaDataTable, it will convert them to a DataTable before writing it, using ConvertTo-DbaDataTable. This setting controls how Timespan objects are converted"
Set-DbatoolsConfig -FullName 'commands.write-dbadatatable.sizetype' -Value 'Int64' -Initialize -Validation string -Description "When passing random objects at Write-DbaDataTable, it will convert them to a DataTable before writing it, using ConvertTo-DbaDataTable. This setting controls how Size objects are converted"
Set-DbatoolsConfig -FullName 'commands.write-dbadatatable.ignorenull' -Value $false -Initialize -Validation bool -Description "When passing random objects at Write-DbaDataTable, it will convert them to a DataTable before writing it, using ConvertTo-DbaDataTable. This setting controls whether null objects will be ignored, rather than generating an empty row"
Set-DbatoolsConfig -FullName 'commands.write-dbadatatable.raw' -Value $false -Initialize -Validation bool -Description "When passing random objects at Write-DbaDataTable, it will convert them to a DataTable before writing it, using ConvertTo-DbaDataTable. This setting controls whether all properties will be stored as string (`$true) or as much as possible in their native type (`$false)"