# halt on first error
$ErrorActionPreference = "Stop"
# print Information stream
$InformationPreference = "Continue"

$rootPath = Switch ($Host.name) {
	'Visual Studio Code Host' { split-path $psEditor.GetEditorContext().CurrentFile.Path }
	'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
	'ConsoleHost' { $PSScriptRoot }
}

$rootPath = $rootPath | Split-Path -Parent

$config = Get-Content "$rootPath\Publish\PublishConfig.json" | ConvertFrom-Json
$ModuleName = (Get-ChildItem "$rootPath\Modules")[0].Name

# update "FunctionsToExport" in psd1 file with latest/current functions
. "$rootPath\Publish\UpdateFunctionsToExport.ps1"

Test-ModuleManifest -Path "$rootPath\Modules\$ModuleName\$ModuleName.psd1"

Publish-Module -NuGetApiKey $config.ApiKey -Path "$rootPath\Modules\$ModuleName"

Start-Process -FilePath "https://www.powershellgallery.com/packages/$ModuleName"