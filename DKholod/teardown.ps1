function Tear-Down(
	[string] $publishsettingsPath,
	[string] $clusterName,
	[string] $vmName1,
	[string] $vmName2,
	[string] $sqlServerName
)
{
	$retryNum = 20
	$serviceName = "$clusterName-vm"
	$cloudServiceName = "$clusterName-service"
	$vmCloudServiceName = "$clusterName-vm"
	$storageName = ($clusterName + "storage1").ToString().ToLower()
	$affinityName = "$clusterName-affinity"
	$networkName = "$clusterName-vnet"
	
	# 0. Set-up environment
	if ([string]::IsNullOrWhiteSpace($publishsettingsPath) -Or (-Not (Test-Path $publishsettingsPath))) {
		Write-Host "Error. *.Publishsettings was not found." -foregroundcolor Red
		return
	}
	
	Write-Host "Importing Azure publish file from $publishsettingsPath"
	Import-AzurePublishSettingsFile $publishsettingsPath -Verbose
	$subscriptionName = (([xml]([System.IO.File]::ReadAllText($publishsettingsPath))) | Select-Xml -XPath "//PublishData/PublishProfile/Subscription/@Name").Node.Value
	Select-AzureSubscription -SubscriptionName $subscriptionName -Default
	
	# 1.VMs+VHD
	$vm = Get-AzureVM -ServiceName $serviceName -Name $vmName1 -Verbose
	if ($vm){
		Write-Host 'Removing VM and related VHD  $serviceName\$vmName1'
		Remove-AzureVM -ServiceName $serviceName -Name $vmName1 -Verbose -DeleteVHD
		Write-Host "done" -foregroundcolor Green
	}
	$vm = Get-AzureVM -ServiceName $serviceName -Name $vmName2 -Verbose
	if ($vm){
		Write-Host 'Removing VM and related VHD  $serviceName\$vmName2'
		Remove-AzureVM -ServiceName $serviceName -Name $vmName2 -Verbose -DeleteVHD
		Write-Host "done" -foregroundcolor Green
	}

	#2.Cloud services SQL VM and Web
	$srv = Get-AzureService -Verbose | Where {$_.ServiceName -eq $vmCloudServiceName} 
	if ($srv) {
		Write-Host "Removing cloud service $sqlServiceName"
		Remove-AzureService -ServiceName $vmCloudServiceName -Force -Verbose
	}
	else {
		Write-Host "Service $sqlServiceName was not found" -foregroundcolor Yellow
	}
	
	$srv = Get-AzureService -Verbose | Where {$_.ServiceName -eq $cloudServiceName}
	if ($srv) {
		Write-Host "Removing cloud service $cloudServiceName"
		Remove-AzureService -ServiceName $cloudServiceName -Force -Verbose
	}
	else {
		Write-Host "Service $cloudServiceName was not found" -foregroundcolor Yellow
	}
	
	#3. Storage account
	$storage = Get-AzureStorageAccount -Verbose | Where {$_.StorageAccountName -eq $storageName}
	if ($storage) {
		for($i=1; $i -le $retryNum; $i++) {
			
			try{
				# Check if any disks is alive
				$disksForClean = Get-AzureDisk | WHERE { $_.AffinityGroup -eq $affinityName }
				foreach($diskForClean in $disksForClean){
					Write-Host "Removing disk: " + $diskForClean.DiskName
					Remove-AzureDisk -DiskName $diskForClean.DiskName
				}
				
				Write-Host "Removing storage account $storageName"
				$storageDeleteResult = Remove-AzureStorageAccount -StorageAccountName $storageName -Verbose			
				if ($storageDeleteResult -and $storageDeleteResult.OperationStatus -eq "Succeeded")
				{
					$storageDeleteResult
					break;
				}
			}catch{
			}
			Write-Host "Operation failed. Execution paused. Attempt $i/$retryNum"
			Start-Sleep -s 30
		}
	}
	else {
		Write-Host "Storage $storageName was not found" -foregroundcolor Yellow
	}
	
	#4. SQL DB
	if ([string]::IsNullOrWhiteSpace($sqlServerName)) {
		Write-Host "Azure SQL server was not specified" -foregroundcolor Yellow
	}
	else {
		$azueSqlServer = Get-AzureSqlDatabaseServer -Verbose | Where {$_.ServerName -eq $sqlServerName}
		if ($azueSqlServer) {
			Write-Host "Removing SQL Azure server $sqlServerName"
			Remove-AzureSqlDatabaseServer -ServerName $sqlServerName -Force -Verbose
		}
		else {
			Write-Host "Azure SQL server $sqlServerName was not found" -foregroundcolor Yellow
		}
	}
	
	#5. Virtual network
	$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
	$tempFileName = $env:TEMP + "\azurevnetconfig.$timestamp.netcfg"
	Get-AzureVNetConfig -ExportToFile $tempFileName
	Write-Host "Current network configuration saved: $tempFileName"
	if (Test-Path $tempFileName) {
		[xml]$netcfgContent = Get-Content $tempFileName
		$xPathTemplate = "//e:NetworkConfiguration/e:VirtualNetworkConfiguration/e:VirtualNetworkSites/e:VirtualNetworkSite[@name='$networkName']"
		$namespace = @{e="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration"}
		$networkNode = Select-Xml -Xml $netcfgContent -XPath $xPathTemplate -Namespace $namespace
		
		if ($networkNode) {	
			$networkNode.Node.ParentNode.RemoveChild($networkNode.Node)
			$netcfgContent.Save($tempFileName)
			Write-Host "Removing network $networkName and updating network configuration"
			Set-AzureVNetConfig -configurationpath $tempFileName -Verbose
		}
		else {
			Write-Host "No network found to remove" -foregroundcolor Yellow
		}
	}
	else {
		Write-Host "No network found to remove" -foregroundcolor Yellow
	}
	
	#6. Affinity
	$affinity = Get-AzureAffinityGroup -Verbose | Where {$_.Name -eq $affinityName}
	if ($affinity)
	{
		for($i=1; $i -le $retryNum; $i++) {
			Write-Host "Removing Affinity group $affinityName"
			$affinityResult = Remove-AzureAffinityGroup -Name $affinityName -Verbose
			
			if ($affinityResult -and $affinityResult.OperationStatus -eq "Succeeded")
			{
				$affinityResult
				break;
			}
			
			Write-Host "Operation failed. Execution paused. Attempt $i/$retryNum"
			Start-Sleep -s 30
		}
	}
	else {
		Write-Host "No Affinity group $affinityName was found" -foregroundcolor Yellow
	}
	
	Write-Host "Tear down for cluster $clusterName - done" -foregroundcolor Green
}

Get-Date

##########################################################################
$publishsettingsPath = 'C:\AzurePublishsettings\Azure Pass-3-14-2015-credentials.publishsettings'
$clusterName = "azurekiev"
$sqlServerName = ''
##########################################################################

Tear-Down   -clusterName $clusterName `
			-publishsettingsPath $publishsettingsPath `
			-vmName1 "azuredemovm1" `
			-vmName2 "azuredemovm2" `
			-sqlServerName $sqlServerName

Get-Date