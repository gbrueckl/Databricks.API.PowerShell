# Set-DatabricksEnvironment is already done by the caller!
$testCaseName = "TestCase_001_Secrets"
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Secrets API ..."
$scopeName = "MyTestScope"
$secretName = "MySecretPassword"

$currentScope = Get-DatabricksSecretScope | Where-Object ($_.name -eq $scopeName)
if($currentScope)
{
	Remove-DatabricksSecretScope -ScopeName $scopeName -ErrorAction SilentlyContinue
}

try
{
	$x = Add-DatabricksSecretScope -ScopeName $scopeName -Verbose
	Get-DatabricksSecretScope -Verbose

	Add-DatabricksSecret -ScopeName $scopeName -SecretName $secretName -StringValue "Pass@word1234!" -Verbose
	$enc = [system.Text.Encoding]::UTF8
	$secretText = "This is a secret value" 
	$secretBytes = $enc.GetBytes($secretText) 
	Add-DatabricksSecret -ScopeName $scopeName -SecretName "MySecret2" -BytesValue $secretBytes -Verbose
	Get-DatabricksSecret -ScopeName $scopeName -Verbose
}
finally
{
	Write-Information "Starting Cleanup for testcase $testCaseName ..."
	Remove-DatabricksSecret -ScopeName $scopeName -SecretName $secretName -ErrorAction SilentlyContinue
	Remove-DatabricksSecretScope -ScopeName $scopeName -ErrorAction SilentlyContinue
	Write-Information "Finished Cleanup for testcase $testCaseName"
}



