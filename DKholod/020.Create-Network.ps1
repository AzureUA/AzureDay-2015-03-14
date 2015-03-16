function Create-Network([string] $clusterName, [Object[]]$networkConfig)
{
    $affinityName = "$clusterName-affinity"
    $networkName = "$clusterName-vnet"
    $timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
    $tempFileName = $env:TEMP + "\azurevnetconfig.$timestamp.netcfg"
    
    #Get configuration from existing network
    Get-AzureVNetConfig -ExportToFile $tempFileName
    
    Write-Host $tempFileName
    if (Test-Path $tempFileName) {
        $sourceFileName = $tempFileName
    } else {
        $sourceFileName = Create-Network-CreateTemplate
    }
    
    [xml]$xml = [System.IO.File]::ReadAllText($sourceFileName)
    
    #### #### #### #### #### #### #### #### #### #### #### ####
    $xmlNs = "http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration"
    $xmlNss = @{"d" = $xmlNs}
    $vnSite = ($xml | Select-Xml -XPath "//d:NetworkConfiguration/d:VirtualNetworkConfiguration/d:VirtualNetworkSites" -Namespace $xmlNss).Node
    
    # VNet
    #### #### #### #### #### #### #### #### #### #### #### ####
    $vnetSite = $xml.CreateElement("VirtualNetworkSite", $xmlNs)
    $vnSite.AppendChild($vnetSite) | Out-Null
    
    $nameAttr = $xml.CreateAttribute("name")
    $nameAttr.Value = $networkName
    $vnetSite.Attributes.Append($nameAttr) | Out-Null
    $affGrAttr = $xml.CreateAttribute("AffinityGroup")
    $affGrAttr.Value = $affinityName
    $vnetSite.Attributes.Append($affGrAttr) | Out-Null
    
    # AddressSpace
    #### #### #### #### #### #### #### #### #### #### #### ####
    $addrSpace = $xml.CreateElement("AddressSpace", $xmlNs)
    $vnetSite.AppendChild($addrSpace) | Out-Null
    $addrSpacePrefix = $xml.CreateElement("AddressPrefix", $xmlNs)
    $addrSpacePrefix.InnerText = $networkConfig.AddressSpace
    $addrSpace.AppendChild($addrSpacePrefix) | Out-Null
    
    # SubNets
    #### #### #### #### #### #### #### #### #### #### #### ####
    $subNets = $xml.CreateElement("Subnets", $xmlNs)
    $vnetSite.AppendChild($subNets) | Out-Null
    foreach($subnet in $networkConfig.Subnets){
        if([string]::IsNullOrEmpty($subnet.Name) -eq $true){
            continue
        }
        $sn = $xml.CreateElement("Subnet", $xmlNs)
        $sn.SetAttribute("name", $subnet.Name)
        $subNets.AppendChild($sn) | Out-Null
        $snAddrPrefix = $xml.CreateElement("AddressPrefix", $xmlNs)
        $snAddrPrefix.InnerText = $subnet.AddressPrefix
        $sn.AppendChild($snAddrPrefix) | Out-Null
    }
    
    $xml.Save($tempFileName)
    
    #### #### #### #### #### #### #### #### #### #### #### ####
    
	Write-Host "from configuration $tempFileName"
    Set-AzureVNetConfig -configurationpath $tempFileName -Verbose    
}

function Create-Network-CreateTemplate()
{
    $fileName = $env:TEMP + "\template.netcfg"
    
    $xml = new-object System.Xml.XmlDocument
    $xmlNs = "http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration"
    $xml.CreateXmlDeclaration("1.0", "utf-8", $null) | Out-Null
    $nc = $xml.CreateElement("NetworkConfiguration", $xmlNs)
    $xml.AppendChild($nc) | Out-Null
    $vc = $xml.CreateElement("VirtualNetworkConfiguration", $xmlNs)
    $nc.AppendChild($vc) | Out-Null
    $dns = $xml.CreateElement("Dns", $xmlNs)
    $vc.AppendChild($dns) | Out-Null
    $vnSite = $xml.CreateElement("VirtualNetworkSites", $xmlNs)
    $vc.AppendChild($vnSite) | Out-Null
    $xml.Save($fileName)
    
    return $fileName
}

function Test()
{
    $clusterName = "testnet"
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
    Create-Network -clusterName $clusterName -networkConfig $networkConfig.Network
}

#Test