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

$moduleName = $ModuleName = (Get-ChildItem "$rootPath\Modules")[0].Name
$psdFilePath = "$rootPath\Modules\$moduleName\$moduleName.psd1"

$PublicFunctions = @( Get-ChildItem -Path "$rootPath\Modules\$moduleName\Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue )
$PublicFunctions = $PublicFunctions | Where-Object { $_.Name -inotlike "*-PREVIEW.ps1" }

# WARNING: If the Alias definition changes, this also has to be changed in the DatabricksPS.pms1 file!
function Get-AliasForFunction {
	[CmdletBinding()]
	param ([Parameter()] [string] $FunctionName )
	process {

	if($PSVersiontable.PSEdition -eq "Desktop")
	{
		# in PS Desktop we dont have $validVerb.AliasPrefix
		return $null
	}

    $standardVerbs = Get-Verb

    $validVerb = $standardVerbs | Where-Object { $_.Verb -eq $FunctionName.Split("-")[0]}
		if($validVerb)
		{
			$aliasFunction = $FunctionName.Split("-")[1]
			# replace specific values that would cause duplicates - only upper-case chars are kept for the final alias!
			$aliasFunction = $aliasFunction.Replace('Databricks', 'DBR') 
			$aliasFunction = $aliasFunction.Replace('Context', 'CTX') 
			$aliasFunction = $aliasFunction.Replace('Command', 'CMD') 
			$aliasFunction = $aliasFunction.Replace('Membership', 'MS') 
			$aliasFunction = $aliasFunction.Replace('InstancePool', 'IPL') 
			$aliasFunction = $aliasFunction.Replace('InstanceProfile', 'IPFL') 
			$aliasFunction = $aliasFunction -creplace '([^A-Z]*)', ''
			$alias = "$($validVerb.AliasPrefix)$aliasFunction"

			return $alias.ToLower()
		}
    return $null
	}
}

$standardVerbs = Get-Verb
$exportedCmdlets = @()
$exportedAliases = @()
foreach($import in $PublicFunctions)
{
	Write-Information "Reading available functions from $($import.FullName) ..."
	$content = Get-Content $import.FullName
	# find all functions - search for "Function" or "function" followed by some whitespaces and the function name
	# function name has to contain a "-"
	$regEx = '[Ff]unction\s+(\S+\-\S+)\s'
	$functions = [regex]::Matches($content, $regEx) | ForEach-Object { $_.Groups[1].Value}
	
	Write-Information "$($functions.Count) functions found! Adding them to list ..."
	foreach($function in $functions)
	{
		$exportedCmdlets += @($function)

		$alias = Get-AliasForFunction -FunctionName $function

		if($alias)
		{
			$exportedAliases += @($alias)

			Write-Information "`tAdding Alias $alias for function $function ..."
		}
	}
}

# WARNING: If the Alias definition changes, this also has to be changed in the DatabricksPS.pms1 file!
$staticAliases = [ordered]@{
	"Get-DatabricksCommandStatus"         = "Get-DatabricksCommand"
	"Get-DatabricksSQLEndpoint"           = "Get-DatabricksSQLWarehouse"
	"Add-DatabricksSQLEndpoint"           = "Add-DatabricksSQLWarehouse"
	"Update-DatabricksSQLEndpoint"        = "Update-DatabricksSQLWarehouse"
	"Remove-DatabricksSQLEndpoint"        = "Remove-DatabricksSQLWarehouse"
	"Stop-DatabricksSQLEndpoint"          = "Stop-DatabricksSQLWarehouse"
	"Start-DatabricksSQLEndpoint"         = "Start-DatabricksSQLWarehouse"
	"Update-DatabricksSQLEndpointConfig"  = "Update-DatabricksSQLWarehouseConfig"
	"Get-DatabricksSQLEndpointConfig"     = "Get-DatabricksSQLWarehouseConfig"
}

foreach ($alias in $staticAliases.GetEnumerator()) {
	$exportedAliases += @($alias.Name)
}

if($exportedAliases.Count -ne ($exportedAliases | Select-Object -Unique).Count)
{
	Write-Information "---- ERROR - Duplicate Aliases:"
	$exportedAliases | Group-Object |
	Where-Object -FilterScript {
		$_.Count -gt 1
	} |
	Select-Object -ExpandProperty Group
	Write-Error "Duplicate Alias found!"
}

$psdContent = Get-Content $psdFilePath -Raw

# find "FunctionsToExport" and replace them with currently existing functions
$regEx = '(FunctionsToExport\s*=\s*@\()([^\)]*)(\))' # use 3 groups of which the second is replaced using Regex-Replace
$matches = [regex]::Matches($psdContent, $regEx)

$cmdletsToExport = "`n'" + ($exportedCmdlets -join "', `n'") + "'`n"
$psdContent = [regex]::Replace($psdContent, $regEx, '$1' + $cmdletsToExport + '$3')

# find "AliasesToExport" and replace them with currently existing functions
$regEx = '(AliasesToExport\s*=\s*@\()([^\)]*)(\))' # use 3 groups of which the second is replaced using Regex-Replace
$matches = [regex]::Matches($psdContent, $regEx)

$aliasesToExport = "`n'" + ($exportedAliases -join "', `n'") + "'`n"
$psdContent = [regex]::Replace($psdContent, $regEx, '$1' + $aliasesToExport + '$3').Trim()

Write-Information "Writing updated Content to $psdFilePath ..."
$psdContent | Out-File "$psdFilePath" -Encoding "UTF8"

