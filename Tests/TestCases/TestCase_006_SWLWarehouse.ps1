# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing SQL Warehouse API ..."
$testWarehouseName = "DatabricksPS_AutomatedTest"


Write-Information "Checking if SQL Warehouse  '$testWarehouseName' already exists ..."
$current = Get-DatabricksSQLWarehouse | Where-Object { $_.name -in @($testWarehouseName) }

if ($current) {
	# Remove-DatabricksSCIMGroup -GroupID $currentToken.id -ErrorAction SilentlyContinue
	Write-Warning "SQL Warehouse '$testWarehouseName' already exists: $($current.id)"
	Write-Warning "You can manually remove it by running: Remove-DatabricksSQLWarehouse -SQLEndpointID $($current.id) -ErrorAction SilentlyContinue"

	Write-Error "SQL Warehouse '$testWarehouseName' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the SQL Warehouse and delete it manually before running the test again."
}

try {
	Write-Information "Adding SQL Warehouse '$testWarehouseName' ..."
	$new = Add-DatabricksSQLWarehouse `
		-Name $testWarehouseName `
		-ClusterSize "2X-Small" `
		-MinNumClusters 1 `
		-MaxNumClusters 4 `
		-AutoStopMinutes 22 `
		-Tags @{firsttag = "My first tag"} `
		-EnablePhoton $false `
		-EnableServerlessCompute $false `
		-Channel CHANNEL_NAME_CURRENT `
		-SpotInstancePolicy RELIABILITY_OPTIMIZED

	Write-Information "Updating SQL Warehouse '$testWarehouseName' ($($new.id)) (parameters) ..."
	$updated = Update-DatabricksSQLWarehouse -SQLEndpointID $new.id `
			-Name "$testWarehouseName-Updated" `
			-ClusterSize "X-Small" `
			-MinNumClusters 2 `
			-MaxNumClusters 2 `
			-AutoStopMinutes 11 `
			-Tags @{firsttag = "My first tag changed"; new_tag = "a new tag"} `
			-EnablePhoton $true `
			-EnableServerlessCompute $true `
			-Channel CHANNEL_NAME_PREVIEW `
			-SpotInstancePolicy COST_OPTIMIZED

	Write-Information "Updating SQL Warehouse '$testWarehouseName' ($($updated.id)) (piped) ..."
	$current = Get-DatabricksSQLWarehouse -SQLEndpointID $updated.id
	$current.min_num_clusters = 3
	$current.max_num_clusters = 3
	$current.channel = "CHANNEL_NAME_CURRENT" # this is not supposed to work as ValueFromPipelineByPropertyName=$false for this parameter

	$x = $current | Update-DatabricksSQLWarehouse


	Write-Information "Removing SQL Warehouse '$testWarehouseName' ($($new.id)) ..."
	$new | Remove-DatabricksSQLWarehouse

	Write-Information "Reading SQL Warehouse Config (using Alias) ..."
	$config = Get-DatabricksSQLEndpointConfig

	Write-Information "Updating SQL Warehouse Config (using Alias) ..."
	$config | Update-DatabricksSQLEndpointConfig -Force

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$existing = Get-DatabricksSQLWarehouse | Where-Object { $_.name -in @($testWarehouseName) }
	if ($existing) {
		Remove-DatabricksSQLWarehouse -SQLEndpointID $existing.id
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



