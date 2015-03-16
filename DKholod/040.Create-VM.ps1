function Create-VM(
[string] $clusterName, 
[string] $instanceSize,
[string] $adminUsername,
[string] $password,
[string] $vmImageName,
[string] $vmName,
[string] $availabilitySetName 
)
{
    $storageName = ($clusterName + "storage1").ToString().ToLower()
    $serviceName = "$clusterName-vm"
    $affinityName = "$clusterName-affinity"
    $networkName = "$clusterName-vnet"
    $subnetname = "vms"    
    
    $imageName = ( Get-AzureVMImage | Where-Object { $_.Label -like $vmImageName } | Select -ExpandProperty ImageName )[0]
    Write-Host "VM image name $imageName"
    Set-AzureSubscription -SubscriptionName ((Get-AzureSubscription -Current).SubscriptionName) -CurrentStorageAccountName $storageName -Verbose
    
    $srv = Get-AzureService -Verbose | Where {$_.ServiceName -eq $serviceName}
    if ($srv) {
        New-AzureQuickVM    -Windows `
                            -ServiceName $serviceName `
                            -Name $vmName `
                            -ImageName $imageName `
                            -InstanceSize $instanceSize `
                            -AdminUsername $adminUsername `
                            -Password $password `
                            -VNetName $networkName `
                            -SubnetNames $subnetname `
                            -AvailabilitySetName $availabilitySetName `
                            -Verbose
    }
    else {
        # if service do not exist specify affinity group 
        New-AzureQuickVM    -Windows `
                            -ServiceName $serviceName `
                            -Name $vmName `
                            -ImageName $imageName `
                            -InstanceSize $instanceSize `
                            -AdminUsername $adminUsername `
                            -Password $password `
                            -VNetName $networkName `
                            -AffinityGroup $affinityName `
                            -SubnetNames $subnetname `
                            -AvailabilitySetName $availabilitySetName `
                            -Verbose
    }
    
    # Open SQL endpoints
    # Get-AzureVM -ServiceName $serviceName -Name $vmName | Add-AzureEndpoint -Name "MSSQL" -Protocol "tcp" -PublicPort 1433 -LocalPort 1433 | Update-AzureVM
}