function Create-SqlAzureDB(
[string] $location, 
[string] $sqlAzureLogin, 
[string] $sqlAzurePassword,
[string] $dbName, 
[string] $dbEdition,
[string] $dbPerformanceLevel)
{
	#Create SQL server
	Write-Host "Creating Azure Sql Server" -ForegroundColor White
	$sqlAzureServer = New-AzureSqlDatabaseServer -location $location -AdministratorLogin $sqlAzureLogin -AdministratorLoginPassword $sqlAzurePassword -Verbose
	$sqlAzureServer
	
	#Setup firewall rule
	$sqlAzureServerName = $sqlAzureServer.ServerName
	Write-Host "Dissabling firewall" -ForegroundColor White
	New-AzureSqlDatabaseServerFirewallRule -ServerName $sqlAzureServerName -RuleName "DissableFirewall" -StartIPAddress '0.0.0.0' -EndIPAddress '255.255.255.255' -Verbose
		
	# Allow Azure Services
	Write-Host "Setup firewall rule allow Azure Services" -ForegroundColor White
	New-AzureSqlDatabaseServerFirewallRule -ServerName $sqlAzureServerName -AllowAllAzureServices -RuleName "AllowAllAzureServices" -Verbose

	#Create connection
	$sqlAzureServer = Get-AzureSqlDatabase -ServerName $sqlAzureServerName
	$sqlAzureServerCredential = new-object System.Management.Automation.PSCredential($sqlAzureLogin, ($sqlAzurePassword  | ConvertTo-SecureString -asPlainText -Force))
	$ctx = New-AzureSqlDatabaseServerContext -Credential $sqlAzureServerCredential -ServerName $sqlAzureServerName

	#Create DB
	Write-Host "Creating DB $dbName" -ForegroundColor White
	$performanceLevel = Get-AzureSqlDatabaseServiceObjective -Context $ctx -ServiceObjectiveName $dbPerformanceLevel
	$result = New-AzureSqlDatabase -ConnectionContext $ctx -DatabaseName $dbName -Edition $dbEdition -MaxSizeGB 1 -ServiceObjective $performanceLevel -Collation "SQL_Latin1_General_CP1_CI_AS" -Verbose
	
	if ($result -and $result.ServiceObjectiveAssignmentStateDescription  -eq "Complete")
	{
		$createdDbName = $result.Name;
		Write-Host "DB $createdDbName created" -ForegroundColor Green
	}
	else
	{
		Write-Host "error" -ForegroundColor Red
	}
}