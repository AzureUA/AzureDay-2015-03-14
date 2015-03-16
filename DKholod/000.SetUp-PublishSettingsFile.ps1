function SetUp-PublishSettingsFile(
[string] $publishsettingsPath
)
{
	# To download publish settings file
	# Get-AzurePublishSettingsFile
	
	# Read subscription from publish xml, only one subscription allowed in xml file in current implementation
	$subscriptionName = (([xml]([System.IO.File]::ReadAllText($publishsettingsPath))) | Select-Xml -XPath "//PublishData/PublishProfile/Subscription/@Name").Node.Value
	Write-Host "Importing Azure publish file from $publishsettingsPath"
	Import-AzurePublishSettingsFile $publishsettingsPath -Verbose
	Select-AzureSubscription -SubscriptionName $subscriptionName -Default
	Write-Host 'Done' -foregroundcolor "Green"
}