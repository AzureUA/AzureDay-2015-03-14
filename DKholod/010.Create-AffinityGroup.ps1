function Create-AffinityGroup(
[string] $clusterName, 
[string] $location)
{
	#Supported locations 10/17/2014
	#South Central US
	#Central US
	#East US 2
	#East US
	#West US
	#North Europe
	#West Europe
	#East Asia
	#Southeast Asia
	#Japan West

	$affinityLabel = "$clusterName-affinity"
	$affinityName = "$clusterName-affinity"
	$affinityDescription = "Affinity group for applications deployment in $location region."
	
	Write-Host "Creating affinity $affinityName in $location"
	New-AzureAffinityGroup	-Name $affinityName `
										-Location $location `
										-Label $affinityLabel `
										-Description $affinityDescription `
										-Verbose
}