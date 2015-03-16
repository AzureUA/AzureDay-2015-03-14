function Create-CloudService([string] $clusterName)
{
	$affinityName = "$clusterName-affinity"
	$cloudServiceName = "$clusterName-service"
	$cloudServiceLabel = "$clusterName-service"
	$cloudServiceDesc = "Primary cloud service for $cloudServiceName"
	
	Write-Host "Creating cloud service: $cloudServiceName"
	New-AzureService -AffinityGroup $affinityName -ServiceName $cloudServiceName -Description $cloudServiceDesc -Label $cloudServiceLabel -Verbose
}