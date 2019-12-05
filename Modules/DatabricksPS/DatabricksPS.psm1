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

#endregion

# $PublicFunctions  = @( Get-ChildItem -Path "$(Split-Path -Parent $psise.CurrentFile.FullPath)\Public\*.ps1" -ErrorAction SilentlyContinue )
# $PrivateFunctions  = @( Get-ChildItem -Path "$(Split-Path -Parent $psise.CurrentFile.FullPath)\Private\*.ps1" -ErrorAction SilentlyContinue )

#Get public and private function definition files.
$PublicFunctions  = @( Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue )

#Dot source the files
foreach($import in @($PublicFunctions + $PrivateFunctions))
{
  try
  {
    . $import.fullname
  }
  catch
  {
    Write-Error -Message "Failed to import functions from file $($import.fullname): $_"
  }
}


# The dynamic export of module members was removed and now the .psd1 file is updated with the 
# latest functions that exist in the .ps1 files under /Public and /Private
# This update is done right before the module is published to the gallery using the script
# /Publish/UpdateFunctionsToExport.ps1

foreach($import in $PublicFunctions)
{
  Write-Verbose "Exporting functions from $($import.FullName) ..."
  $content = Get-Content $import.FullName
  # find all functions - search for "Function" or "function" followed by some whitespaces and the function name
  # function name has to contain a "-"
  $regEx = '[Ff]unction\s+(\S+\-\S+)\s'
  $matches = [regex]::Matches($content, $regEx)
	
  Write-Verbose "$($matches.Count) functions found! Importing them ..."
  $matches | ForEach-Object { 
            #Write-Host "Exporting function '$($_.Groups[1]) ..."
            #Export-ModuleMember -Function  $_.Groups[1] 
          }
}

# 2019-12-05: 
# (Get-azLocation | Where-Object { $_.Providers -contains 'Microsoft.Databricks'}).Location | Sort-Object
$script:dbAvailableRegionsAzure = @(
  'australiacentral',
  'australiacentral2',
  'australiaeast',
  'australiasoutheast',
  'brazilsouth',
  'canadacentral',
  'canadaeast',
  'centralindia',
  'centralus',
  'eastasia',
  'eastus',
  'eastus2',
  'francecentral',
  'japaneast',
  'japanwest',
  'koreacentral',
  'koreasouth',
  'northcentralus',
  'northeurope',
  'southafricanorth',
  'southafricawest',
  'southcentralus',
  'southeastasia',
  'southindia',
  'uaenorth',
  'uksouth',
  'ukwest',
  'westeurope',
  'westindia',
  'westus',
  'westus2'
)

# 2019-12-05:
# https://docs.databricks.com/administration-guide/cloud-configurations/aws/regions.html
$script:dbAvailableRegionsAWS = @(
  'us-west-2',
  'us-west-1',
  'us-east-1',
  'sa-east-1',
  'eu-west-1',
  'eu-west-3',
  'eu-central-1',
  'ap-south-1',
  'ap-southeast-2',
  'ap-southeast-1',
  'ap-northeast-2',
  'ap-northeast-1',
  'ca-central-1'
)

$script:dbApiRootUrls = @()
$script:dbApiRootUrls += $script:dbAvailableRegionsAzure | ForEach-Object { "https://$_.azuredatabricks.net"}
$script:dbApiRootUrls += $script:dbAvailableRegionsAWS | ForEach-Object { "https://$_.cloud.databricks.com"}