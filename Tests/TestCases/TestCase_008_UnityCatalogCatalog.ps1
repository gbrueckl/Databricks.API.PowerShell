# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


$apiToTest = "UnityCatalog Catalog"
Write-Information "Testing $apiToTest API ..."
$testCatalogName = $script:unityCatalogCatalogName

if(-not $testCatalogName) {
	Write-Warning "Testcase '$testCaseName' cannot be executed because the required variable 'unityCatalogStorageCredentialName' is not set!"
	exit
}

Write-Information "Checking if $apiToTest '$testCatalogName' already exists ..."
$current = Get-UnityCatalogCatalog | Where-Object { $_.name -in @($testCatalogName) }

if ($current) {
	# Remove-UnityCatalogCatalog -CatalogName $testCatalogName -Force
	Write-Warning "$apiToTest '$testCatalogName' already exists: $($current.name)"
	Write-Warning "You can manually remove it by running: Remove-UnityCatalogCatalog -CatalogName $testCatalogName -Force -ErrorAction SilentlyContinue"

	Write-Error "$apiToTest '$testCatalogName' already exists and real data may be overwritten during the test!
	Please check the $apiToTest and delete it manually before running the test again."
}

try {
	Write-Information "Adding $apiToTest '$testCatalogName' ..."
	$new = Add-UnityCatalogCatalog -CatalogName $testCatalogName

	Write-Information "Updating $apiToTest '$testCatalogName' ($($new.name)) (parameters) ..."
	$updated = Update-UnityCatalogCatalog -CatalogName $testCatalogName -Comment "MyComment" -NewCatalogName "$testCatalogName-Updated" -Properties @{"MyProperty" = "MyValue"}

	Write-Information "Updating $apiToTest '$testCatalogName' ($($updated.name)) (piped) ..."
	$current = Get-UnityCatalogCatalog -CatalogName "$testCatalogName-Updated"
	$current.comment = "MyUpdateComment"
	$current.properties = @{"MySecondProperty" = "MySecondValue"}

	$updated2 = $current | Update-UnityCatalogCatalog -NewCatalogName $testCatalogName

	Write-Information "Removing $apiToTest '$testCatalogName' ($($updatd2.name)) ..."
	$updated2 | Remove-UnityCatalogCatalog -Force

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$existing = Get-UnityCatalogCatalog -CatalogName "$testCatalogName" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogCatalog -CatalogName "$testCatalogName" -Force
	}

	$existing = Get-UnityCatalogCatalog -CatalogName "$testCatalogName-Updated" -ErrorAction SilentlyContinue
	if ($existing) {
		Remove-UnityCatalogCatalog -CatalogName "$testCatalogName-Updated" -Force
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



