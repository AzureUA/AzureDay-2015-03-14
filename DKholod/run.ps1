."./000.SetUp-PublishSettingsFile.ps1"
."./010.Create-AffinityGroup.ps1"
."./020.Create-Network.ps1"
."./030.Create-StorageAccount.ps1"
."./040.Create-VM.ps1"
."./050.Create-CloudService.ps1"
."./060.Deploy-CloudServiceCertificate.ps1"
."./070.Deploy-CloudService.ps1"
."./080.Create-SqlAzureDB.ps1"
."./200.Warmup-App.ps1"

Get-Date

##########################################################################
#$publishsettingsPath = 'C:\AzurePublishsettings\Azure Pass-3-14-2015-credentials.publishsettings'
$publishsettingsPath = 'C:\AzurePublishsettings\DEVELOPMENT Pay-As-You-Go-CAT Beta - Gamma MSDN-Pay-As-You-Go-Denis Kholod-3-14-2015-credentials.publishsettings'

$clusterName = "azureday16"

$location = "West US"

$configString = '{"Network": {
        "AddressSpace":
            "10.0.0.0/8",
        "Subnets": [
                { "Name": "fronts", "AddressPrefix": "10.1.0.0/23" },
                { "Name": "services", "AddressPrefix": "10.2.0.0/23" },
                { "Name": "vms", "AddressPrefix": "10.3.0.0/23" }
        ]
       }
    }';    
$networkConfig = $configString | ConvertFrom-JSON

$vmInstanceSize = "Basic_A2"
$vmAdminUsername = "openadmin"
$vmPassword = "p@`$`$w0rd2"    
$vmImageName = "Windows Server Essentials Experience on Windows Server 2012 R2"
$availabilitySetName = $clusterName+"avset"

$cloudServiceCertificatePath = "$PSScriptRoot\artifacts\AzureDemo.pfx"
$cloudServiceCertificatePassword = "p@`$`$w0rd"
$cloudServiceSlot = "Production"
$cloudServicePackagePath = "$PSScriptRoot\artifacts\AzureDemo.cspkg"
$cloudServiceConfiguration = "$PSScriptRoot\artifacts\ServiceConfiguration.Cloud.cscfg"

$sqlAzureLogin = "openadmin"
$sqlAzurePassword = "p@`$`$w0rd2"
$dbName = "AzureDemoDb"
$dbEdition = "Premium"  
$dbPerformanceLevel = "P3"
##########################################################################

SetUp-PublishSettingsFile -publishsettingsPath $publishsettingsPath

#$sql = Create-SqlAzureDB    -location $location `
#                            -sqlAzureLogin $sqlAzureLogin `
#                            -sqlAzurePassword $sqlAzurePassword `
#                            -dbName $dbName `
#                            -dbEdition $dbEdition `
#                            -dbPerformanceLevel $dbPerformanceLevel

#Write-Host "Db name is" $sql[0].ServerName + ".database.windows.net"

Create-AffinityGroup -clusterName $clusterName -location $location

Create-Network -clusterName $clusterName -networkConfig $networkConfig.Network

Create-StorageAccount -clusterName $clusterName

Create-CloudService -clusterName $clusterName

Deploy-CloudServiceCertificate -clusterName $clusterName -cloudServiceCertificatePath $cloudServiceCertificatePath -cloudServiceCertificatePassword $cloudServiceCertificatePassword

Deploy-CloudService -clusterName $clusterName -cloudServiceSlot $cloudServiceSlot -cloudServicePackagePath $cloudServicePackagePath -cloudServiceConfiguration $cloudServiceConfiguration

# vm 1
Create-VM   -clusterName $clusterName `
            -instanceSize $vmInstanceSize `
            -adminUsername $vmAdminUsername `
            -password $vmPassword `
            -vmImageName $vmImageName `
            -vmName 'azuredemovm1' `
            -availabilitySetName $availabilitySetName

# vm 2
Create-VM   -clusterName $clusterName `
            -instanceSize $vmInstanceSize `
            -adminUsername $vmAdminUsername `
            -password $vmPassword `
            -vmImageName $vmImageName `
            -vmName 'azuredemovm2' `
            -availabilitySetName $availabilitySetName

Warmup-App -clusterName $clusterName

Get-Date