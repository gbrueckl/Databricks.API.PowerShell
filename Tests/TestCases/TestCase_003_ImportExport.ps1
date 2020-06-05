# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."

# when executed as script (not via UI/ISE), the location was already set
$rootPath = Get-Location

Write-Information "Testing Import/Export ..."
$contentPathLocal = "$rootPath\Tests\Content"
$contentPathExport = "$rootPath\Tests\Content_Export"

$contentPathOnline = "/DatabricksPS_Test"

Write-Information "Checking if Path/Folder '$contentPathOnline' already exists in the Databricks Workspace ..."
$dbItem = $null
try {
	$dbItem = Get-DatabricksWorkspaceItem -Path $contentPathOnline
}
catch { }

if ($dbItem) {
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
	Export-DatabricksEnvironment -CleanLocalRootPath -LocalPath $contentPathExport -Artifacts "Workspace" -WorkspaceRootPath $contentPathTest
}
finally {
	Write-Information "Starting Cleanup for testcase $testCaseName ..."
	#Remove-DatabricksWorkspaceItem -Path $contentPathTest -Recursive $true
	Write-Information "Finished Cleanup for testcase $testCaseName"
}

<#
$workspaceItemName = 'TestNotebook2.scala.ipynb'
$dbPathItem = '\DatabricksPS_Test\MyFolder1\TestNotebook2.scala'.Replace('\', '/')

$tokens = $workspaceItemName.Split('.')

(Split-Path $dbPathItem -Parent) + "\" + $($tokens[0..($tokens.Length - 3)] -join ".")
$dbPathItem = $tokens[0..($tokens.Length - 3)] -join "." # remove last two tokens
Get-DatabricksWorkspaceItem -Path "/" -ChildItems
Get-DatabricksWorkspaceItem -Path $contentPathOnline
#>

$origFiles = Get-ChildItem -Path "$contentPathLocal/Workspace/$contentPathOnline"
$exportedFiles = Get-ChildItem -Path "$contentPathExport/Workspace/$contentPathOnline"