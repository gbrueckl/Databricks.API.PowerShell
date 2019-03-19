# Set-DatabricksEnvironment is already done by the caller!
Write-Information "TestCase_002_Files"


Write-Information "Testing DBFS API ..."
$fileName = "myFile.txt"
$localFilePath = ".\Tests\Content\$fileName"
$dbfsPath = "/myTestFolder/dbfs/$fileName"
$localTempFolder = ".\Tests\Content\_TEMP"
try
{
	Upload-DatabricksFSFile -Path $dbfsPath -LocalPath $localFilePath
	Download-DatabricksFSFile -Path $dbfsPath -LocalPath "$localTempFolder\$fileName"
}
finally
{
	Write-Information "Starting Cleanup ..."
	Remove-Item -Path $localFilePath -Recurse -Force
	Write-Information "Finished Cleanup"
}



