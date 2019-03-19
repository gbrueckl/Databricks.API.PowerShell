# Set-DatabricksEnvironment is already done by the caller!
Write-Information "TestCase_002_Files"

# if executed from PowerShell ISE
if ($psise) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent | Split-Path -Parent
}
else {
	$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
}


Write-Information "Testing DBFS API ..."
$fileName = "myFile.txt"
$localFilePath = "$rootPath\Tests\Content\$fileName"
$dbfsPath = "/myTestFolder/dbfs/$fileName"
$localTempFolder = "$rootPath\Tests\Content\_TEMP"
try
{
	Upload-DatabricksFSFile -Path $dbfsPath -LocalPath $localFilePath -Overwrite $true -BatchSize 10
	New-Item -Path $localTempFolder -ItemType "directory" -Force
	Download-DatabricksFSFile -Path $dbfsPath -LocalPath "$localTempFolder\$fileName" -Overwrite $true -BatchSize 10
}
finally
{
	Write-Information "Starting Cleanup ..."
	Remove-Item -Path $localTempFolder -Recurse -Force
	Write-Information "Finished Cleanup"
}



