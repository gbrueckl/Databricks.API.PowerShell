# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Tokens API ..."
$testTokenNameUser = "DatabricksPS_AutomatedTest_Token_User"
$testTokenNameAdmin = "DatabricksPS_AutomatedTest_Token_Admin"

Write-Information "Checking if Token  '$testTokenNameUser' or '$testTokenNameAdmin' already exists ..."
$currentToken = Get-DatabricksApiToken | Where-Object { $_.comment -in @($testTokenNameUser, $testTokenNameAdmin) }

if ($currentToken) {
	# Remove-DatabricksSCIMGroup -GroupID $currentToken.id -ErrorAction SilentlyContinue
	Write-Warning "Token '$testTokenNameUser' or '$testTokenNameAdmin' already exists: $currentToken"
	Write-Warning "You can manually remove it by running: Remove-DatabricksApiToken -TokenID $($currentToken.id) -ErrorAction SilentlyContinue"

	Write-Error "Token '$testTokenNameUser' or '$testTokenNameUserAdmin' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the token and delete it manually before running the test again."
}

try {
	$testUser = Get-DatabricksSCIMUser -Me

	Write-Information "Adding Token '$testTokenNameUser' (User-mode) ..."
	$currentToken = Add-DatabricksApiToken -Comment $testTokenNameUser -LifetimeSeconds 300
	
	Write-Information "Getting token again (User-mode) ..."
	$userToken = Get-DatabricksApiToken | Where-Object { $_.comment -eq $testTokenNameUser }

	Write-Information "Removing token again (User-mode) ..."
	$userToken | Remove-DatabricksApiToken

	Write-Information "Adding Token '$testTokenNameAdmin' (Admin-mode) ..."
	$currentToken = Add-DatabricksApiToken -Comment $testTokenNameAdmin -LifetimeSeconds 300
	
	Write-Information "Getting token again by UserName (Admin-mode) ..."
	$adminToken1 = Get-DatabricksApiToken -Admin -CreatedByUsername $testUser.name | Where-Object { $_.comment -eq $testTokenNameAdmin }

	Write-Information "Getting token again by UserID (Admin-mode) ..."
	$adminToken2 = Get-DatabricksApiToken -Admin -CreatedByUserID $testUser.id | Where-Object { $_.comment -eq $testTokenNameAdmin }

	if ($adminToken1 -and $adminToken2 -and (Compare-Object $adminToken1 $adminToken2)) {
		Write-Warning "Expected Token:"
		Write-Warning $adminToken1
		Write-Warning "Actual Token:"
		Write-Warning $adminToken2
		Write-Error "Tokens did not match!"
	}

	Write-Information "Removing token again (Admin-mode) ..."
	$adminToken1 | Remove-DatabricksApiToken -Admin
	
	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$allTokens = Get-DatabricksApiToken -Admin -CreatedByUserID $testUser.id
	if ($userToken.token_id -in $allTokens.token_id) {
		Remove-DatabricksApiToken -TokenID $userToken.token_id -ErrorAction SilentlyContinue
	}
	if ($adminToken1.token_id -in $allTokens.token_id) {
		Remove-DatabricksApiToken -TokenID $adminToken1.token_id -ErrorAction SilentlyContinue
	}
	
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



