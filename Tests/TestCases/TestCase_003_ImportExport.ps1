# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."

# if executed from PowerShell ISE
if (-not $PSCommandPath) { 
	$rootPath = Switch ($Host.name) {
		'Visual Studio Code Host' { Split-Path $psEditor.GetEditorContext().CurrentFile.Path }
		'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
		'ConsoleHost' { $PSScriptRoot }
	}
	$rootPath = $rootPath | Split-Path -Parent | Split-Path -Parent
}
else {
	# when executed as script (not via UI/ISE), the location was already set
	$rootPath = Get-Location
}

Write-Information "Testing Import/Export ..."
$workspacePathOnline = $script:testWorkspaceFolder # must also match whats in /Content/Workspace/XXX !!!
$dbfsPathOnline = $script:testDBFSFolder # must also match whats in /Content/DBFS/XXX !!!


$contentPathLocal = "$rootPath\Tests\Content"
$contentPathExport = "$rootPath\Tests\Content_Export"

Write-Information "Checking if Path/Folder '$workspacePathOnline' already exists in the Databricks Workspace ..."
$dbItem = $null
try {
	$dbItem = Get-DatabricksWorkspaceItem -Path $workspacePathOnline
}
catch { }

if ($dbItem) {
	# Remove-DatabricksWorkspaceItem -Path $workspacePathOnline -Recursive $true
	Write-Warning $dbItem
	Write-Error "Path/Folder '$workspacePathOnline' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the path and delete it manually before running the test again."
}

try {
	Write-Information "Importing Workspace content ..."
	Import-DatabricksEnvironment -LocalPath $contentPathLocal -Artifacts "Workspace" -OverwriteExistingWorkspaceItems

	Write-Information "Importing Workspace content again to test overwrites ..."
	Import-DatabricksEnvironment -LocalPath $contentPathLocal -Artifacts "Workspace" -OverwriteExistingWorkspaceItems

	Write-Information "Exporting Workspace to compare with original content ..."
	Export-DatabricksEnvironment -CleanLocalRootPath -LocalPath $contentPathExport -Artifacts "Workspace" -WorkspaceRootPath $workspacePathOnline
	
	
	$sourceFolder = "$contentPathLocal\Workspace$workspacePathOnline".replace('/', '\')
	$targetFolder = "$contentPathExport\Workspace$workspacePathOnline".replace('/', '\')
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

	Write-Information "Importing DBFS content from '$contentPathLocal\DBFS' ..."
	Import-DatabricksEnvironment -LocalPath $contentPathLocal -Artifacts "DBFS"

	Write-Information "Exporting DBFS content to '$contentPathExport\DBFS' ..."
	# need to copy original file to export folder as the Export only downloads files that exist locally!
	Copy-Item -Path "$contentPathLocal\DBFS" -Destination "$contentPathExport\DBFS" -Recurse
	Export-DatabricksEnvironment -LocalPath $contentPathExport -Artifacts "DBFS"

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."
	Remove-DatabricksWorkspaceItem -Path $workspacePathOnline -Recursive $true -ErrorAction SilentlyContinue
	Remove-Item -Path $contentPathExport -Recurse -Force -ErrorAction SilentlyContinue
	Remove-DatabricksFSItem -Path $dbfsPathOnline -Recursive $true -ErrorAction SilentlyContinue
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}