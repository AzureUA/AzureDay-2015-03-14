function Deploy-CloudService(
[string] $clusterName, 
[string] $cloudServiceSlot, 
[string] $cloudServicePackagePath,
[string] $cloudServiceConfiguration)
{
    #to upload package from blob storage
    #$cloudServicePackagePath = "http://test112211.blob.core.windows.net/deployment/Wilco.AzureService.cspkg"
    $date = Get-Date
    $networkName = "$clusterName-vnet"
    $storageName = ($clusterName + "storage1").ToString().ToLower()
    $azureStorageKey = (Get-AzureStorageKey -StorageAccountName $storageName).Primary    
    $cloudServiceName = "$clusterName-service"
    $cloudServiceDeploymentLabel = "Initial automated deployment $date"
    
    $timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
    $cloudServiceDeploymentConfiguration = $env:TEMP + "\ServiceConfiguration.Cloud.$timestamp.cscfg"
    
    Write-Host "using deployment package $cloudServicePackagePath"
    
    # Modify configuration before deployment
    [xml]$configXml = [System.IO.File]::ReadAllText($cloudServiceConfiguration)
    $configXml.PreserveWhitespace = $true
    $configXmlns = @{ d = "http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration" }
    
    # VNet name
    ($configXml | Select-Xml -Xpath "//d:ServiceConfiguration/d:NetworkConfiguration/d:VirtualNetworkSite/@name" -Namespace $configXmlns).Node.Value = $networkName
    
    $configXml.Save($cloudServiceDeploymentConfiguration)
    
	Write-Host "Starting to deploy service with configuration file $cloudServiceDeploymentConfiguration"
    Set-AzureSubscription -SubscriptionName ((Get-AzureSubscription -Current).SubscriptionName) -CurrentStorageAccountName $storageName -Verbose
	Write-Host "Deploying $cloudServiceName to $cloudServiceSlot"
    New-AzureDeployment -ServiceName $cloudServiceName -Slot $cloudServiceSlot -Package $cloudServicePackagePath -Configuration $cloudServiceDeploymentConfiguration -Label $cloudServiceDeploymentLabel  -Verbose
}

function Test()
{
    
    
    
}