# halt on first error
$ErrorActionPreference = "Stop"
# print Information stream
$InformationPreference = "Continue"

# Read-Host -AsSecureString -Prompt "Value to Secure" | ConvertFrom-SecureString

$rootPath = Switch ($Host.name) {
	'Visual Studio Code Host' { split-path $psEditor.GetEditorContext().CurrentFile.Path }
	'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
	'ConsoleHost' { $PSScriptRoot }
}

$rootPath = $rootPath | Split-Path -Parent
Push-Location $rootPath

. "$rootPath\Modules\DatabricksPS\Private\General.ps1"

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

function Convert-SecureObject (
	[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)] [object]$InputObject,
	[string]$SecureInputObjectSuffix = "_Secure"
) {
	Write-Verbose $InputObject.GetType().Name
	if ($InputObject -eq $null) {
		Write-Verbose "Found a null-Value ..."
		return $null
	}
	elseif ($InputObject.GetType().Name -eq 'PSCustomObject') {
		Write-Verbose "Found an PSCustomObject ..."
		return $InputObject | ConvertTo-Hashtable | Convert-SecureObject
	}
	elseif ($InputObject.GetType().Name -eq 'Object[]') {
		# array
		Write-Verbose "Found an Array ..."
		$ret = @()
		foreach ($item in $InputObject) {
			$ret.Add((Convert-SecureObject -InputObject $item -SecureInputObjectSuffix $SecureInputObjectSuffix))
		}
		return $ret
	}
	elseif ($InputObject.GetType().Name -eq 'Hashtable') {
		# hashtable
		Write-Verbose "Found a Hashtable ..."
		$allKeys = @() + $InputObject.Keys
		foreach ($key in $allKeys) {
			Write-Verbose "$key : $($InputObject[$key].GetType().Name)"
			$newValue = Convert-SecureObject -InputObject $InputObject[$key] -SecureInputObjectSuffix $SecureInputObjectSuffix
			if ($key.EndsWith($SecureInputObjectSuffix)) {
				Write-Verbose "Found a Secured Key: '$key'"
				$InputObject.Add($key.Replace($SecureInputObjectSuffix, ""), $newValue)
				$InputObject.Remove($key)
			}
			else {
				$InputObject[$key] = $newValue
			}
		}
		return $InputObject
	}
	elseif ($InputObject.GetType().Name -eq 'String') {
		# convert the secure string back to a plaintext InputObject
		try {
			return [System.Net.NetworkCredential]::new("x", ($InputObject | ConvertTo-SecureString)).Password
		}
		catch {
			return $InputObject
		}
	}

	return $InputObject
}

Remove-Module -Name "DatabricksPS" -ErrorAction SilentlyContinue -Force
Import-Module "$rootPath\Modules\DatabricksPS" -Verbose

# find examples for automated tests: '.EXAMPLE\n#AUTOMATED_TEST:TestName\n' ... '.EXAMPLE' or '#>'
$regEx = "\s*\.EXAMPLE\s+#AUTOMATED_TEST:(.*)\n((?:.|\r|\n)+?)\s+(?=\.EXAMPLE|#>)"

$config = Get-Content "$rootPath\Tests\TestEnvironments.config.json" | ConvertFrom-Json

#$activeEnvironments = $config.environments | Out-GridView -PassThru
$activeEnvironments = $config.environments | Where-Object { $_.isActive }
foreach ($environment in $activeEnvironments) { 
	try {
		Write-Information "Testing Environment '$($environment.name)' ..."

		$plainEnvironment = Convert-SecureObject $environment -SecureInputObjectSuffix "_Secure"

		if ($plainEnvironment.environmentVariables) {
			foreach ($envVar in $plainEnvironment.environmentVariables.GetEnumerator()) {
				Write-Information "Setting EnvironmentVariable '$($envVar.Name)'"
				Set-Item -Path "env:$($envVar.Name)" -Value $envVar.Value
			}
		}

		$authentication = $plainEnvironment.authentication
		# Special case to manage PSCredentials
		if ($authentication.Keys -contains "Credential") {
			$username = $authentication.Credential.Username
			# Convert InputObject to SecureString-String to be stored in config file:
			# "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
			$password = $authentication.Credential.Password | ConvertTo-SecureString -AsPlainText -Force
			$credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
			$authentication["Credential"] = $credential
		}

		Set-DatabricksEnvironment @authentication -Verbose

		if ($plainEnvironment.basicConnectionTestOnly) {
			Write-Information "Only running basic connection test to check if authentication did work properly ..."
			Test-DatabricksEnvironment
			continue
		}
	
		# prepare DBFS for single-command tests
		$script:testDBFSFolder = '/' + $plainEnvironment.testConfig.dbfsFolder.Trim('/') + '/'
		Add-DatabricksFSDirectory -Path $script:testDBFSFolder

		$script:testWorkspaceFolder = '/' + $plainEnvironment.testConfig.workspaceFolder.Trim('/') + '/'
		$script:testSecretScope = $plainEnvironment.testConfig.secretScope.Trim()

		# Unity Catalog
		$script:unityCatalogCatalogName = $plainEnvironment.testConfig.unityCatalogCatalogName
		$script:unityCatalogStorageCredentialResourceID = $plainEnvironment.testConfig.unityCatalogStorageCredentialResourceID
		$script:unityCatalogStorageCredentialName = $plainEnvironment.testConfig.unityCatalogStorageCredentialName
		$script:unityCatalogExternalLocatinURL = $plainEnvironment.testConfig.unityCatalogExternalLocatinURL
	
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
			#$testCase = $testcases[2]
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
		Remove-DatabricksFSItem -Path $script:testDBFSFolder -Recursive $true -ErrorAction SilentlyContinue
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
