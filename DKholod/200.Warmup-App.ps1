function Warmup-App ([string]$clusterName)
{
	$maxWaitMinutes = 20
	$endWaitTime = [DateTime]::Now.Add([TimeSpan]::FromMinutes($maxWaitMinutes))
	$currentSpan = New-TimeSpan -Start $endWaitTime -End ([DateTime]::Now)	
	$serviceName = [string]::Format("{0}-service", $clusterName)
	
	# Waiting loop
	Write-Host "waiting instances Ready state"
	while($currentSpan.Minutes -le 0){
		$notReadyRoles = (Get-AzureDeployment -ServiceName $serviceName).RoleInstanceList | WHERE { $_.InstanceStatus -ne "ReadyRole" }
		if($notReadyRoles.Count -eq 0){
			break
		}
	}
	
	if($notReadyRoles.Count -ne 0){
		throw ([string]::Format("Instances {0} not comes to Ready state in {1} minutes, please review.", $notReadyRoles.Count, $maxWaitMinutes))
	}
	
	$url = [string]::Format("http://{0}-service.cloudapp.net", $clusterName)
	
	Write-Host "Calling WarmUp url: $url"
	Warmup-App-OpenUrl -url $url
}

function Warmup-App-OpenUrl([string]$url){
    $request = [System.Net.HttpWebRequest]::Create($url) 
    $request.set_Timeout([Timespan]::FromMinutes(5).TotalMilliseconds)
    $response = $request.GetResponse()
	
	switch($response.StatusCode){
		{ $_ -eq [System.Net.HttpStatusCode]::Ok } {
				Write-Host "WarmUp - successful" -color Green
				break;
			}
		default {
				Write-Host  "WarmUp - unsuccessful, code is: " + $response.StatusCode -color Red
				throw ("error warmup url, response is: " + $response.StatusCode)
			}
	}
}