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


Function Set-DatabricksEnvironment 
{
	<#
			.SYNOPSIS
			Sets global module config variables AccessToken, CloudProvider and ApirRootUrl    
			.DESCRIPTION
			Sets global module config variables AccessToken, CloudProvider and ApirRootUrl    
			.PARAMETER PBIAPIUrl
			The url for the PBI API
			.PARAMETER AccessToken
			The AccessToken to use to access the Databricks API
			For example: dapi1234abcd32101691ded20b53a1326285
			.PARAMETER ApiRootUrl
			The URL of the API. 
			For Azure, this could be 'https://westeurope.azuredatabricks.net'
			For AWS, this could be 'https://abc-12345-xaz.cloud.databricks.com'
			.PARAMETER CloudProvider
			The CloudProvider where the Databricks workspace is hosted. Can either be 'Azure' or 'AWS'.
			If not provided, it is derived from the ApiRootUrl parameter
			.EXAMPLE
			Set-PBIModuleConfig -pbiAPIUrl "https://api.powerbi.com/beta/myorg" -AzureADAppId "YOUR Azure AD GUID"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $AccessToken = $null,
		[Parameter(Mandatory = $true, Position = 2)] [string] $ApiRootUrl = $null,
		[Parameter(Mandatory = $false, Position = 3)] [string] [ValidateSet("Azure","AWS")] $CloudProvider = $null
	)

	Write-Verbose "Setting [System.Net.ServicePointManager]::SecurityProtocol to [System.Net.SecurityProtocolType]::Tls12 ..."
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
	Write-Verbose "Done!"

	#region check AccessToken
	$paramToCheck = 'AccessToken'
	Write-Verbose "Checking if Parameter -$paramToCheck was provided ..."
	if($AccessToken -ne $null)
	{
		Write-Verbose "Parameter -$paramToCheck provided! Setting global $paramToCheck ..."
		$script:dbAccessToken = $AccessToken
		Write-Verbose "Done!"
	}
	else
	{
		Write-Warning "Parameter -$paramToCheck was not provided!"
	}
	#endregion

	#region check ApiRootUrl
	$paramToCheck = 'ApiRootUrl'
	Write-Verbose "Checking if Parameter -$paramToCheck was provided ..."
	if($ApiRootUrl -ne $null)
	{
		Write-Verbose "$paramToCheck provided! Setting global $paramToCheck ..."
		$script:dbApiRootUrl = $ApiRootUrl.Trim('/')
		Write-Verbose "Done!"

		Write-Verbose "Setting global dbApiFullUrl ..."
		$script:dbApiFullUrl = $ApiRootUrl.Trim('/') + "/api/2.0"
		Write-Verbose "Done!"
	}
	else
	{
		Write-Warning "Parameter -$paramToCheck was not provided!"
	}

	#region check CloudProvider
	$paramToCheck = 'CloudProvider'
	Write-Verbose "Checking if Parameter -$paramToCheck was provided ..."
	if($CloudProvider -ne $null)
	{
		Write-Verbose "Parameter -$paramToCheck provided! Setting global $paramToCheck ..."
		$script:dbCloudProvider = $CloudProvider
		Write-Verbose "Done!"
	}
	else
	{
		Write-Warning "Parameter -$paramToCheck was not provided!"
		Write-Verbose "Trying to derive $paramToCheck from ApiRootUrl ..."
		Write-Verbose "Checking if ApiRootUrl contains '.azuredatabricks.' ..."
		if($ApiRootUrl -ilike "*.azuredatabricks.*")
		{
			Write-Verbose "'.azuredatabricks.' found in ApiRootUrl - Setting CloudProvider to 'Azure' ..."
			$script:dbCloudProvider = "Azure"
		}
		else
		{
			Write-Verbose "'.azuredatabricks.' found in ApiRootUrl - Setting CloudProvider to 'AWS' ..."
			$script:dbCloudProvider = "AWS"
		}
		Write-Verbose "Done!"
	}
	#endregion

	$script:dbInitialized = $true
}

Function Test-Initialized
{
	[CmdletBinding()]
	param ()

	Write-Verbose "Checking if Databricks environment has been initialized yet ..."
	if($script:dbInitialized -eq $false)
	{
		Write-Error "Databricks environment has not been initialized yet! Please run Set-DatabricksEnvironment before any other cmdlet!"
	}
	Write-Verbose "Databricks environment already initialized."
}

Function Get-DatabricksHeader
{
	[CmdletBinding()]
	param ()

	Write-Verbose "Getting Headers for Databricks API call ..."
	return @{
		Authorization = "Bearer $script:dbAccessToken"
		"Content-Type" = "application/json"
	}
}

Function Remove-WorkspaceItem 
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic. Exampl
			e of request:
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#delete
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.PARAMETER Recursive 
			The flag that specifies whether to delete the object recursively. It is false by default. Please note this deleting directory is not atomic. If it fails in the middle, some of objects under this directory may be deleted and cannot be undone.
			.EXAMPLE
			Remove-WorkspaceItem -Path <<>> -Recursive <<>>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Recursive
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/delete"
	$requestMethod = "POST"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = Path 
		recursive = Recursive 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}
				
Function Export-WorkspaceItem
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Exports a notebook or contents of an entire directory. If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. One can only export a directory in DBC format. If the exported data would exceed size limit, this call returns an error MAX_NOTEBOOK_SIZE_EXCEEDED. This API does not support exporting a library.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#export
			.PARAMETER Path 
			The absolute path of the notebook or directory. Exporting directory is only support for DBC format. This field is required.
			.PARAMETER LocalPath 
			The local path where the exported file is stored.
			.PARAMETER Format 
			This specifies the format of the exported file. By default, this is SOURCE. However it may be one of: SOURCE, HTML, JUPYTER, DBC. The value is case sensitive.
			.EXAMPLE
			Export-WorkspaceItem -Path "/" -LocalPath "C:\myExport.dbc" -Format "DBC"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $LocalPath, 
		[Parameter(Mandatory = $false, Position = 3)] [string] [ValidateSet("SOURCE", "HTML", "JUPYTER", "DBC")] $Format = "SOURCE"
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/export"
	$requestMethod = "GET"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		format = $Format  
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters
				
	$exportBytes = [Convert]::FromBase64String($result.content)
	[IO.File]::WriteAllBytes($LocalPath, $exportBytes)
}

Function Get-WorkspaceItemDetails
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Gets the status of an object or a directory. If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#get-status
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.EXAMPLE
			Get-WorkspaceItemDetails -Path "/Users/user@example.com/project/ScaleExampleNotebook"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/get-status"
	$requestMethod = "GET"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Import-WorkspaceItem
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Imports a notebook or the contents of an entire directory. If path already exists and overwrite is set to false, this call returns an error RESOURCE_ALREADY_EXISTS. One can only use DBC format to import a directory. Example of request, where content is the base64-encoded string of 1+1:
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#import
			.PARAMETER Path 
			The absolute path of the notebook or directory. Importing directory is only support for DBC format. This field is required.
			.PARAMETER Format 
			This specifies the format of the file to be imported. By default, this is SOURCE. However it may be one of: SOURCE, HTML, JUPYTER, DBC. The value is case sensitive.
			.PARAMETER Language 
			The language. If format is set to SOURCE, this field is required; otherwise, it will be ignored.
			.PARAMETER LocalPath 
			The local file that is to be imported. This has a limit of 10 MB. If the limit (10MB) is exceeded, exception with error code MAX_NOTEBOOK_SIZE_EXCEEDED will be thrown. This parameter might be absent, and instead a posted file will be used. See Import a notebook or directory for more information about how to use it.
			.PARAMETER Overwrite 
			The flag that specifies whether to overwrite existing object. It is false by default. For DBC format, overwrite is not supported since it may contain a directory.
			.EXAMPLE
			Import-WorkspaceItem -Path "/myImportedFolder -Format "DBC" -LocalPath "C:\myFileToImport.dbc" -Overwrite $false
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [string] [ValidateSet("SOURCE", "HTML", "JUPYTER", "DBC")] $Format = "SOURCE", 
		[Parameter(Mandatory = $false, Position = 3)] [string] [ValidateSet("SCALA", "PYTHON", "SQL", "R")] $Language, 
		[Parameter(Mandatory = $true, Position = 4)] [string] $LocalPath, 
		[Parameter(Mandatory = $false, Position = 5)] [bool] $Overwrite = $false
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/import"
	$requestMethod = "POST"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader
	
	$fileBytes = [IO.File]::ReadAllBytes($LocalPath)
	$content = [Convert]::ToBase64String($fileBytes)

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		format = $Format 
		language = $Language 
		content = $Content 
		overwrite = $Overwrite 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-WorkspaceItem
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Lists the contents of a directory, or the object if it is not a directory. If the input path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#list
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.EXAMPLE
			Get-WorkspaceItem -Path "/"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/list"
	$requestMethod = "GET"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function New-WorkspaceDirectory
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Creates the given directory and necessary parent directories if they do not exists. If there exists an object (not a directory) at any prefix of the input path, this call returns an error RESOURCE_ALREADY_EXISTS. Note that if this operation fails it may have succeeded in creating some of the necessary parrent directories.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#mkdirs
			.PARAMETER Path 
			The absolute path of the directory. If the parent directories do not exist, it will also create them. If the directory already exists, this command will do nothing and succeed. This field is required.
			.EXAMPLE
			New-WorkspaceDirectory -Path "/myNewDirectory"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = $script:dbApiRootUrl + "/2.0/workspace/mkdirs"
	$requestMethod = "POST"
	Write-Verbose "Final ApiURL: $apiUrl"

	#Set headers
	$headers = Get-DatabricksHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}