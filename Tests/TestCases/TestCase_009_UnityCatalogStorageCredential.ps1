# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


$apiToTest = "UnityCatalog StorageCredential"
Write-Information "Testing $apiToTest API ..."
$testStorageCredentialName = $script:unityCatalogStorageCredentialName
$accessConnectorID = $script:unityCatalogStorageCredentialResourceID

if(-not $testStorageCredentialName) {
	Write-Warning "Testcase '$testCaseName' cannot be executed because the required variable 'unityCatalogStorageCredentialName' is not set!"
	exit
}

Write-Information "Checking if $apiToTest '$testStorageCredentialName' already exists ..."
$current = Get-UnityCatalogStorageCredential | Where-Object { $_.name -in @($testStorageCredentialName) }

if ($current) {
	# Remove-UnityCatalogStorageCredential -StorageCredentialName $testStorageCredentialName -Force
	Write-Warning "$apiToTest '$testStorageCredentialName' already exists: $($current.name)"
	Write-Warning "You can manually remove it by running: Remove-UnityCatalogStorageCredential -StorageCredentialName $testStorageCredentialName -Force -ErrorAction SilentlyContinue"

	Write-Error "$apiToTest '$testStorageCredentialName' already exists and real data may be overwritten during the test!
	Please check the $apiToTest and delete it manually before running the test again."
}

try {
	Write-Information "Adding $apiToTest '$testStorageCredentialName' ..."
	$new = Add-UnityCatalogStorageCredential -StorageCredentialName $testStorageCredentialName -AccessConnectorID $accessConnectorID -SkipValidation -ReadOnly $true -Comment "DatabricksPS Test"

	Write-Information "Updating $apiToTest '$testStorageCredentialName' ($($new.name)) (parameters) ..."
	$updated = Update-UnityCatalogStorageCredential -StorageCredentialName $testStorageCredentialName -Comment "UpdateSuccessful" -NewStorageCredentialName "$testStorageCredentialName-Updated"

	Write-Information "Updating $apiToTest '$testStorageCredentialName' ($($updated.name)) (piped) ..."
	$current = Get-UnityCatalogStorageCredential -StorageCredentialName "$testStorageCredentialName-Updated"
	$current.comment = "MyUpdateComment"
	$current.read_only = $true

	$updated2 = $current | Update-UnityCatalogStorageCredential -NewStorageCredentialName $testStorageCredentialName

	Write-Information "Removing $apiToTest '$testStorageCredentialName' ($($updated2.name)) ..."
	$updated2 | Remove-UnityCatalogStorageCredential -Force

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	Write-Information "Adding $apiToTest '$testStorageCredentialName' for following test cases ..."
	$new = Add-UnityCatalogStorageCredential -StorageCredentialName $testStorageCredentialName -AccessConnectorID $accessConnectorID -SkipValidation -ReadOnly $true -Comment "DatabricksPS Test"

	$existing = Get-UnityCatalogStorageCredential -StorageCredentialName "$testStorageCredentialName" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogStorageCredential -StorageCredentialName $existing.name -Force
	}

	$existing = Get-UnityCatalogStorageCredential -StorageCredentialName "$testStorageCredentialName-Updated" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogStorageCredential -StorageCredentialName $existing.name -Force
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



