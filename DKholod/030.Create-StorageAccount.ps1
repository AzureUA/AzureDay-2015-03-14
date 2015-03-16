function Create-StorageAccount([string] $clusterName)
{
	$affinityName = "$clusterName-affinity"
	$storageName = ($clusterName + "storage1").ToString().ToLower()
	$storageLabel = "$clusterName primary storage account"
	
	Write-Host "Creating storage account $storageName"
	New-AzureStorageAccount -StorageAccountName $storageName -Label $storageLabel -AffinityGroup $affinityName -Verbose
}