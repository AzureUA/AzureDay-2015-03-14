function Deploy-CloudServiceCertificate(
[string] $clusterName, 
[string] $cloudServiceCertificatePath,
[string] $cloudServiceCertificatePassword)
{
	$cloudServiceName = "$clusterName-service"
	Write-Host "Deploying certificate $cloudServiceCertificatePath"
	Add-AzureCertificate -serviceName $cloudServiceName -certToDeploy $cloudServiceCertificatePath –password $cloudServiceCertificatePassword -Verbose
}