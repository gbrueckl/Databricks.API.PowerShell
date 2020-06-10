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
Push-Location $rootPath

function Process-TestScript([string]$TestScript) {
	$TestScript = $TestScript.Replace("/myDBFSTestFolder/", $script:testDBFSFolder)
	$TestScript = $TestScript.Replace("/myWorkspaceTestFolder/", $script:testWorkspaceFolder)
	$TestScript = $TestScript.Replace("myTestSecretScope", $script:testSecretScope)
	
	return $TestScript
}

function Compare-FoldersRecursive (
	[string] $SourcePath,
	[string] $TargetPath 
) {
	$sourceItems = Get-ChildItem -Path $SourcePath -ErrorAction SilentlyContinue

	if (-not $sourceItems) { return @($TargetPath) }

	$targetItems = Get-ChildItem -Path $TargetPath

	$diffs = Compare-Object -ReferenceObject $targetItems -DifferenceObject $sourceItems -Property BaseName
	$diffsOut = @()
	if ($diffs) {
		$diffsOut = $diffsOut + $(Join-Path $TargetPath $diffs.BaseName)
	}

	$targetFolders = $targetItems | Where-Object { $_ -is [System.IO.DirectoryInfo] }

	foreach ($targetFolder in $targetFolders) {
		$diffsSubDir = Compare-FoldersRecursive -SourcePath $targetFolder.FullName.Replace($TargetPath, $SourcePath) -TargetPath $targetFolder.FullName
		if ($diffsSubDir) {
			$diffsOut = $diffsOut + $diffsSubDir
		}
	}

	return $diffsOut
}

$config = Get-Content "$rootPath\Tests\TestEnvironments.config.json" | ConvertFrom-Json

Remove-Module -Name "DatabricksPS" -ErrorAction SilentlyContinue -Force
Import-Module "$rootPath\Modules\DatabricksPS" -Verbose

# find examples for automated tests: '.EXAMPLE\n#AUTOMATED_TEST:TestName\n' ... '.EXAMPLE' or '#>'
$regEx = "\s*\.EXAMPLE\s+#AUTOMATED_TEST:(.*)\n((?:.|\r|\n)+?)\s+(?=\.EXAMPLE|#>)"

$activeEnvironments = $config.environments | Where-Object { $_.isActive }
foreach ($environment in $activeEnvironments) { 
	try {
		Write-Information "Testing Environment $($environment.name) ..."
		$authentication = $environment.authentication | ConvertTo-Hashtable

		if ($authentication.Keys -contains "Credential") {
			$username = $authentication.Credential.Username
			# Convert Value to SecureString-String to be stored in config file:
			# "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
			$password = $authentication.Credential.PasswordSecure | ConvertTo-SecureString
			$credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
			$authentication["Credential"] = $credential
		}

		Set-DatabricksEnvironment @authentication -Verbose
	
		# prepare DBFS for single-command tests
		$script:testDBFSFolder = '/' + $environment.testConfig.dbfsFolder.Trim('/') + '/'
		Add-DatabricksFSDirectory -Path $script:testDBFSFolder

		$script:testWorkspaceFolder = '/' + $environment.testConfig.workspaceFolder.Trim('/') + '/'
		$script:testSecretScope = $environment.testConfig.secretScope.Trim()
	
		$moduleCommands = Get-Command -Module "DatabricksPS"
	
		# Test single commands without dependencies
		foreach ($moduleCommand in $moduleCommands) {
			Write-Information "Testing Command $($moduleCommand.Name) ..."
			$definition = $moduleCommand.Definition
	
			$matches = [regex]::Matches($definition, $regEx)
			Write-Information "Found $($matches.Count) Tests!"

			foreach ($match in $matches) {
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
	
		# complex test-cases with dependencies
		$testCases = Get-ChildItem -Path "$rootPath\Tests\TestCases" -Recurse -Filter "*.ps1"
		foreach ($testCase in $testCases) {
			Write-Information "------------------------------------------------------------"
			Write-Information "Running TestCase file $($testCase.Name) ..."
			. $testCase.FullName
		
			Write-Information "Finished TestCase file $($testCase.Name)!"
			Write-Information "------------------------------------------------------------"
			Write-Information ""
			Write-Information ""
		}
	}
	finally {
		Write-Information "Starting Cleanup for Environment $($environment.name) ..."
		Remove-DatabricksFSItem -Path $script:dbfsTestFolder -Recursive $true -ErrorAction SilentlyContinue
		# WorkspaceFolder and SecretScope are only used within their corresponding test case and the clean-up happens there!
		Write-Information "Finished Cleanup for Environment $($environment.name) ..."
	}
}


<#
Remove-Module -Name "DatabricksPS" -ErrorAction SilentlyContinue -Force
Import-Module "$rootPath\Modules\DatabricksPS"
Set-DatabricksEnvironment -AccessToken "$accessToken" -ApiRootUrl "$apiUrl"
. $testCase.FullName
#>
