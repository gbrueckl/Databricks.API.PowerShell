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

$script:dbAccessToken = $null
$script:dbApiRootUrl = $null
$script:dbApiFullUrl = $null
$script:dbCloudProvider = $null
$script:dbInitialized = $false

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

# Here I might...
# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only

#TODO Parse ps1 files and export each line that begins with "function"
foreach($import in $PublicFunctions)
{
	Write-Verbose "Exporting functions from $($import.FullName) ..."
	$content = Get-Content $import.FullName
	$regEx = '[Ff]unction\s*(\S*)\s'
	$matches = [regex]::Matches($content, $regEx)
	
	Write-Verbose "$($matches.Count) functions found! Importing them ..."
	$matches | ForEach-Object { 
						Write-Host "Exporting function '$($_.Groups[1]) ..."
						Export-ModuleMember -Function  $_.Groups[1] 
					}
}