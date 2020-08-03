# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Secrets API ..."
$scopeName = $script:testSecretScope
$secretName = "MySecretPassword"

Write-Information "Checking if Secret Scope '$scopeName' already exists ..."
$currentScope = Get-DatabricksSecretScope | Where-Object { $_.name -eq $scopeName }

if ($currentScope) {
	# Remove-DatabricksSecretScope -ScopeName $scopeName -ErrorAction SilentlyContinue
	Write-Warning "Secret Scope '$scopeName' already exists: $currentScope"
	Write-Warning "You can manually remove it by running: Remove-DatabricksSecretScope -ScopeName '$scopeName'"

	Write-Error "SecretScope '$currentScope' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the SecretScope and delete it manually before running the test again."
}

try {
	Write-Information "Adding Secret Scope '$scopeName' ..."
	$currentScope = Add-DatabricksSecretScope -ScopeName $scopeName -InitialManagePrincipal "users"
	Get-DatabricksSecretScope

	Write-Information "Adding Secret with -StringValue ..."
	Add-DatabricksSecret -ScopeName $scopeName -SecretName "MySecret1" -StringValue "Pass@word1234!"

	$enc = [system.Text.Encoding]::UTF8
	$secretText = "This is a secret value" 
	$secretBytes = $enc.GetBytes($secretText) 
	Write-Information "Adding Secret with -BytesValue ..."
	Add-DatabricksSecret -ScopeName $scopeName -SecretName "MySecret2" -BytesValue $secretBytes

	Write-Information "Listing secrets of Scope '$scopeName' ..."
	Get-DatabricksSecret -ScopeName $scopeName

	Write-Information "Removing secrets of Scope '$scopeName' ..."
	Get-DatabricksSecret -ScopeName $scopeName | Remove-DatabricksSecret -ScopeName $scopeName

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$currentScope = Get-DatabricksSecretScope | Where-Object { $_.name -eq $scopeName }

	if($currentScope)
	{
		Write-Information "Removing Secret Scope '$scopeName' ..."
		Remove-DatabricksSecretScope -ScopeName $scopeName
	}
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



