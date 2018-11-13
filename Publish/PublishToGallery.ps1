# halt on first error
$ErrorActionPreference = "Stop"
# print Information stream
$InformationPreference = "Continue"

# if executed from PowerShell ISE
if ($psise) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent
}
else {
	$rootPath = (Get-Item $PSScriptRoot).Parent.FullName
}

$config = Get-Content "$rootPath\Publish\PublishConfig.json" | ConvertFrom-Json
$ModuleName = (Get-ChildItem "$rootPath\Modules")[0].Name

Publish-Module -NuGetApiKey $config.ApiKey -Path "$rootPath\Modules\$ModuleName"

Start-Process -FilePath "https://www.powershellgallery.com/packages/$ModuleName"