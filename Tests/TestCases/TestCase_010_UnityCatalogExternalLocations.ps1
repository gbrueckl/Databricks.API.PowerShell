# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


$apiToTest = "UnityCatalog ExternalLocation"
Write-Information "Testing $apiToTest API ..."
$testExternalLocationName = "DatabricksPS_AutomatedTest"
$storageCredentialName = $script:unityCatalogStorageCredentialName
$accessConnectorID = $script:unityCatalogStorageCredentialResourceID
$externalLocationUrl = $script:unityCatalogExternalLocatinURL

if (-not $storageCredentialName) {
	Write-Warning "Testcase '$testCaseName' cannot be executed because the required variable 'unityCatalogStorageCredentialName' is not set!"
	exit
}

Write-Information "Checking if $apiToTest '$testExternalLocationName' already exists ..."
$current = Get-UnityCatalogExternalLocation | Where-Object { $_.name -in @($testExternalLocationName) }

if ($current) {
	# Remove-UnityCatalogExternalLocation -ExternalLocationName $testExternalLocationName -Force
	Write-Warning "$apiToTest '$testExternalLocationName' already exists: $($current.name)"
	Write-Warning "You can manually remove it by running: Remove-UnityCatalogExternalLocation -ExternalLocationName $testExternalLocationName -Force -ErrorAction SilentlyContinue"

	Write-Error "$apiToTest '$testExternalLocationName' already exists and real data may be overwritten during the test!
	Please check the $apiToTest and delete it manually before running the test again."
}

try {
	Write-Information "Adding StorageCredential to use with external location '$storageCredentialName' ..."
	$new = Add-UnityCatalogStorageCredential -StorageCredentialName $storageCredentialName -AccessConnectorID $accessConnectorID -SkipValidation -ReadOnly $true -Comment "DatabricksPS Test"

	Write-Information "Adding $apiToTest '$testExternalLocationName' ..."
	$new = Add-UnityCatalogExternalLocation -ExternalLocationName $testExternalLocationName -URL $externalLocationUrl -CredentialName $storageCredentialName -SkipValidation -Comment "DatabricksPS Test"

	Write-Information "Updating $apiToTest '$testExternalLocationName' ($($new.name)) (parameters) ..."
	$updated = Update-UnityCatalogExternalLocation -ExternalLocationName $new.name -Comment "UpdateSuccessful" -NewExternalLocationName "$testExternalLocationName-Updated"

	Write-Information "Updating $apiToTest '$testExternalLocationName' ($($updated.name)) (piped) ..."
	$current = Get-UnityCatalogExternalLocation -ExternalLocationName "$testExternalLocationName-Updated"
	$current.comment = "MyUpdateComment"
	$current.read_only = $true

	$updated2 = $current | Update-UnityCatalogExternalLocation -NewExternalLocationName $testExternalLocationName -SkipValidation

	Write-Information "Removing $apiToTest '$testExternalLocationName' ($($new.name)) ..."
	$updated2 | Remove-UnityCatalogExternalLocation -Force

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$existing = Get-UnityCatalogExternalLocation -ExternalLocationName "$testExternalLocationName" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogExternalLocation -ExternalLocationName $existing.name -Force
	}

	$existing = Get-UnityCatalogExternalLocation -ExternalLocationName "$testExternalLocationName-Updated" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogExternalLocation -ExternalLocationName $existing.name -Force
	}

	$existing = Get-UnityCatalogStorageCredential -StorageCredentialName $storageCredentialName -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogStorageCredential -StorageCredentialName $existing.name -Force
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



