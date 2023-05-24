<# 

    Official Databricks API documentation:

    - Version 2.0:		https://docs.databricks.com/api/index.html
    - Version 1.2:		https://docs.databricks.com/api/1.2/index.html (not covered by this module, just for reference!)

    Source Code Repository:

    - https://github.com/gbrueckl/Databricks.API.PowerShell
	

    Copyright (c) 2018 Gerhard Brueckl

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

#>

#region Constants/Variables for all cmdlets

# also check /private/General.ps1 - Function Clear-ScriptVariables
$script:dbAccessToken = $null
$script:dbApiRootUrl = $null
$script:dbApiFullUrl = $null
$script:dbCloudProvider = $null
$script:dbInitialized = $false
$script:dbAuthenticationProvider = $null
$script:dbAuthenticationHeader = $null
$script:dbApiCallRetryCount = $null
$script:dbApiCallRetryWait = $null

#endregion

# $PublicFunctions  = @( Get-ChildItem -Path "$(split-path $psEditor.GetEditorContext().CurrentFile.Path)\Public\*.ps1" -ErrorAction SilentlyContinue )
# $PrivateFunctions  = @( Get-ChildItem -Path "$(split-path $psEditor.GetEditorContext().CurrentFile.Path)\Private\*.ps1" -ErrorAction SilentlyContinue )

#Get public and private function definition files.
$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot\Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
foreach ($import in @($PublicFunctions + $PrivateFunctions)) {
  try {
    . $import.fullname
  }
  catch {
    Write-Error -Message "Failed to import functions from file $($import.fullname): $_"
  }
}


# The dynamic export of module members was removed and now the .psd1 file is updated with the 
# latest functions that exist in the .ps1 files under /Public and /Private
# This update is done right before the module is published to the gallery using the script
# /Publish/UpdateFunctionsToExport.ps1

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

foreach ($import in $PublicFunctions) {
  Write-Verbose "Exporting functions from $($import.FullName) ..."
  $content = Get-Content $import.FullName
  # find all functions - search for "Function" or "function" followed by some whitespaces and the function name
  # function name has to contain a "-"
  $regEx = '[Ff]unction\s+(\S+\-\S+)\s'
  $functions = [regex]::Matches($content, $regEx) | ForEach-Object { $_.Groups[1].Value }
	
  Write-Verbose "$($functions.Count) functions found! Adding aliases for them ..."
  foreach ($function in $functions) {
    $alias = Get-AliasForFunction -FunctionName $function

    if ($alias) {
      Set-Alias -Name $alias -value $function -Description "Alias for $function"
    }
  }
}

# WARNING: If the Alias definition changes, this also has to be changed in the UpdateFunctionsToExport.ps1 file!
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
	Set-Alias -Name $alias.Name -Value $alias.Value -Description "Alias for $($alias.Value)"
}