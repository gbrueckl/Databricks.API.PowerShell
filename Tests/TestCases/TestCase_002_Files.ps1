# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."

# if executed from PowerShell ISE
if (-not $PSCommandPath) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent | Split-Path -Parent
}
else {
	# when executed as script (not via UI/ISE), the location was already set
	$rootPath = Get-Location
}

Write-Information "Testing DBFS API ..."
$fileName = "myFile.txt"
$localFilePath = "$rootPath\Tests\Content\$fileName"
$dbfsPath = "/myTestFolder/dbfs/$fileName"
$localTempFolder = "$rootPath\Tests\Content\_TEMP"
try {
	Upload-DatabricksFSFile -Path $dbfsPath -LocalPath $localFilePath -Overwrite $true -BatchSize 10
	New-Item -Path $localTempFolder -ItemType "directory" -Force
	Download-DatabricksFSFile -Path $dbfsPath -LocalPath "$localTempFolder\$fileName" -Overwrite $true -BatchSize 10
}
finally {
	Write-Information "Starting Cleanup for testcase $testCaseName ..."
	Remove-Item -Path $localTempFolder -Recurse -Force -ErrorAction SilentlyContinue
	Remove-DatabricksFSItem $dbfsPath -ErrorAction SilentlyContinue
	Write-Information "Finished Cleanup for testcase $testCaseName"
}



