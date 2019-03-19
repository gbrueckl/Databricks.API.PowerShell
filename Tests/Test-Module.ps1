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

Push-Location $rootPath

function Process-TestScript([string]$TestScript)
{
	$TestScript = $TestScript.Replace("/myTestFolder/", $script:dbfsTestFolder)
	
	return $TestScript
}



$config = Get-Content "$rootPath\Tests\TestEnvironments.config.json" | ConvertFrom-Json

Remove-Module -Name "DatabricksPS" -ErrorAction SilentlyContinue -Force
Import-Module "$rootPath\Modules\DatabricksPS" -Verbose

# find examples for automated tests: '.EXAMPLE\n#AUTOMATED_TEST:TestName\n' ... '.EXAMPLE' or '#>'
$regEx = "\s*\.EXAMPLE\s+#AUTOMATED_TEST:(.*)\n((?:.|\r|\n)+?)\s+(?=\.EXAMPLE|#>)"

$activeEnvironments = $config.environments | Where-Object { $_.isActive }
foreach($environment in $activeEnvironments)
{
	Write-Information "Testing Environment $($environment.name) ..."
	$accessToken = $environment.accessToken
	$apiUrl = $environment.apiRootUrl
	
	Set-DatabricksEnvironment -AccessToken "$accessToken" -ApiRootUrl "$apiUrl" -Verbose
	
	$script:dbfsTestFolder = '/' + $environment.dbfsTestFolder.Trim('/') + '/'
	Add-DatabricksFSDirectory -Path $script:dbfsTestFolder
	
	$moduleCommands = Get-Command -Module "DatabricksPS"
	

	foreach($moduleCommand in $moduleCommands)
	{
		Write-Information "Testing Command $($moduleCommand.Name) ..."
		$definition = $moduleCommand.Definition
	
		$matches = [regex]::Matches($definition, $regEx)
		Write-Information "Found $($matches.Count) Tests!"

		foreach($match in $matches)
		{
			$testCaseName = $match.Groups[1].Value.Trim()
			$testScript = $match.Groups[2].Value.TrimEnd()
			
			$testScript = Process-TestScript -TestScript $testScript
			
			Write-Information "Running Test '$testCaseName' ..."
			Write-Information $testScript
			$finalScript = $ExecutionContext.InvokeCommand.NewScriptBlock($testScript)
			& $finalscript
			Write-Information "Success!"
		}	
	}
	
	$testCases = Get-ChildItem -Path "$rootPath\Tests\TestCases" -Recurse -Filter "*.ps1"
	foreach($testCase in $testCases)
	{
		Write-Information "------------------------------------------------------------"
		Write-Information "Running TestCase file $($testCase.Name) ..."
		. $testCase.FullName
		
		Write-Information "Finished TestCase file $($testCase.Name)!"
		Write-Information "------------------------------------------------------------"
		Write-Information ""
		Write-Information ""
	}
	Remove-DatabricksFSItem -Path $script:dbfsTestFolder -Recursive $true
}
