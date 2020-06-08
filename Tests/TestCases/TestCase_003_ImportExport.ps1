# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."

# when executed as script (not via UI/ISE), the location was already set
$rootPath = Get-Location

Write-Information "Testing Import/Export ..."
$contentPathLocal = "$rootPath\Tests\Content"
$contentPathExport = "$rootPath\Tests\Content_Export"

$contentPathOnline = $script:workspaceTestFolder

Write-Information "Checking if Path/Folder '$contentPathOnline' already exists in the Databricks Workspace ..."
$dbItem = $null
try {
	$dbItem = Get-DatabricksWorkspaceItem -Path $contentPathOnline
}
catch { }

if ($dbItem) {
	# Remove-DatabricksWorkspaceItem -Path $contentPathOnline -Recursive $true
	Write-Warning $dbItem
	Write-Error "Path/Folder '$contentPathOnline' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the path and delete it manually before running the test again."
}

try {
	Write-Information "Starting testcase $testCaseName ..."
	Write-Information "Importing Workspace content ..."
	Import-DatabricksEnvironment -LocalPath $contentPathLocal -Artifacts "Workspace" -OverwriteExistingWorkspaceItems

	Write-Information "Importing Workspace content again to test overwrites ..."
	Import-DatabricksEnvironment -LocalPath $contentPathLocal -Artifacts "Workspace" -OverwriteExistingWorkspaceItems

	Write-Information "Exporting Workspace to compare with original content ..."
	Export-DatabricksEnvironment -CleanLocalRootPath -LocalPath $contentPathExport -Artifacts "Workspace" -WorkspaceRootPath $contentPathOnline -WorkspaceExportFormat "JUPYTER"
	
	
	$sourceFolder = "$contentPathLocal\Workspace$contentPathOnline".replace('/', '\')
	$targetFolder = "$contentPathExport\Workspace$contentPathOnline".replace('/', '\')
	$diffs = Compare-FoldersRecursive -SourcePath $sourceFolder -TargetPath $targetFolder

	$actualDiffs = $diffs | ForEach-Object { $_.Replace($targetFolder, '') }
	
	$expectedDiffs = @(
		'invalidFileExtension2'
		'MyFolder2\invalidFileExtension1'
		'Tests'
	)

	if (Compare-Object $actualDiffs $expectedDiffs) {
		Write-Warning "Expected Diffs:"
		Write-Warning $($expectedDiffs | ConvertTo-Json)
		Write-Warning "Actuald Diffs:"
		Write-Warning $($actualDiffs | ConvertTo-Json)
		Write-Error "Import and Export did not Match!"
	}

	Write-Information "S U C C E S S  -  Testcase $testCaseName finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase $testCaseName ..."
	Remove-DatabricksWorkspaceItem -Path $contentPathOnline -Recursive $true
	Remove-Item -Path $contentPathExport -Recurse -Force
	Write-Information "Finished Cleanup for testcase $testCaseName"
}