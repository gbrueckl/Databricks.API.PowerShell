# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Secrets API ..."
$scopeName = "MyTestScope"
$secretName = "MySecretPassword"

$currentScope = Get-DatabricksSecretScope | Where-Object ($_.name -eq $scopeName)

if ($currentScope) {
	# Remove-DatabricksSecretScope -ScopeName $scopeName -ErrorAction SilentlyContinue
	Write-Warning $currentScope
	Write-Error "SecretScope '$currentScope' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the SecretScope and delete it manually before running the test again."
}

try {
	$x = Add-DatabricksSecretScope -ScopeName $scopeName -InitialManagePrincipal "users"
	Get-DatabricksSecretScope

	Add-DatabricksSecret -ScopeName $scopeName -SecretName $secretName -StringValue "Pass@word1234!"
	$enc = [system.Text.Encoding]::UTF8
	$secretText = "This is a secret value" 
	$secretBytes = $enc.GetBytes($secretText) 
	Add-DatabricksSecret -ScopeName $scopeName -SecretName "MySecret2" -BytesValue $secretBytes
	Get-DatabricksSecret -ScopeName $scopeName

	Write-Information "S U C C E S S  -  Testcase $testCaseName finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase $testCaseName ..."
	Remove-DatabricksSecret -ScopeName $scopeName -SecretName $secretName -ErrorAction SilentlyContinue
	Remove-DatabricksSecretScope -ScopeName $scopeName -ErrorAction SilentlyContinue
	Write-Information "Finished Cleanup for testcase $testCaseName"
}



