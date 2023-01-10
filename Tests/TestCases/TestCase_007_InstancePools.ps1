# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Instance Pool API ..."
$testInstancePoolName = "DatabricksPS_AutomatedTest"


Write-Information "Checking if Instance Pool '$testInstancePoolName' already exists ..."
$current = Get-DatabricksInstancePool | Where-Object { $_.name -in @($testInstancePoolName) }

if ($current) {
	# Remove-DatabricksSCIMGroup -GroupID $currentToken.id -ErrorAction SilentlyContinue
	Write-Warning "Instance Pool '$testInstancePoolName' already exists: $($current.id)"
	Write-Warning "You can manually remove it by running: Remove-DatabricksInstancePool -InstancePoolID $($current.id) -ErrorAction SilentlyContinue"

	Write-Error "Instance Pool '$testInstancePoolName' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the Instance Pool and delete it manually before running the test again."
}

try {
	Write-Information "Adding Instance Pool '$testInstancePoolName' ..."
	$new = Add-DatabricksInstancePool `
		-Name $testInstancePoolName `
		-ClusterSize "2X-Small" `
		-MinNumClusters 1 `
		-MaxNumClusters 4 `
		-AutoStopMinutes 22 `
		-Tags @{firsttag = "My first tag"} `
		-EnablePhoton $false `
		-EnableServerlessCompute $false `
		-Channel CHANNEL_NAME_CURRENT `
		-SpotInstancePolicy RELIABILITY_OPTIMIZED

	Write-Information "Updating Instance Pool '$testInstancePoolName' ($($new.id)) (parameters) ..."
	$updated = Update-DatabricksInstancePool -SQLEndpointID $new.id `
			-Name "$testInstancePoolName-Updated" `
			-ClusterSize "X-Small" `
			-MinNumClusters 2 `
			-MaxNumClusters 2 `
			-AutoStopMinutes 11 `
			-Tags @{firsttag = "My first tag changed"; new_tag = "a new tag"} `
			-EnablePhoton $true `
			-EnableServerlessCompute $true `
			-Channel CHANNEL_NAME_PREVIEW `
			-SpotInstancePolicy COST_OPTIMIZED

	Write-Information "Updating Instance Pool '$testInstancePoolName' ($($updated.id)) (piped) ..."
	$current = Get-DatabricksInstancePool -SQLEndpointID $updated.id
	$current.min_num_clusters = 3
	$current.max_num_clusters = 3
	$current.channel = "CHANNEL_NAME_CURRENT" # this is not supposed to work as ValueFromPipelineByPropertyName=$false for this parameter

	$x = $current | Update-DatabricksInstancePool


	Write-Information "Removing Instance Pool '$testInstancePoolName' ($($new.id)) ..."
	$new | Remove-DatabricksInstancePool

	Write-Information "Reading Instance Pool Config (using Alias) ..."
	$config = Get-DatabricksSQLEndpointConfig

	Write-Information "Updating Instance Pool Config (using Alias) ..."
	$config | Update-DatabricksSQLEndpointConfig -Force

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$existing = Get-DatabricksInstancePool | Where-Object { $_.name -in @($testInstancePoolName) }
	if ($existing) {
		Remove-DatabricksInstancePool -SQLEndpointID $existing.id
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



