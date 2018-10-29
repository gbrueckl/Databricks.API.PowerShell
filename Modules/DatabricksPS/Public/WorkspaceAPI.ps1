Function Delete-DbWorkspaceItem 
{
	<#
			.SYNOPSIS
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			.DESCRIPTION
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#delete
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.PARAMETER Recursive 
			The flag that specifies whether to delete the object recursively. It is false by default. Please note this deleting directory is not atomic. If it fails in the middle, some of objects under this directory may be deleted and cannot be undone.
			.EXAMPLE
			Remove-DbWorkspaceItem -Path <Path> -Recursive $false
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Recursive
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		recursive = $Recursive 
	}
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}
				
Function Export-DbWorkspaceItem
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
			Export-DbWorkspaceItem -Path "/" -LocalPath "C:\myExport.dbc" -Format "DBC"
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
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/export"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

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

Function Get-DbWorkspaceItemDetails
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
			Get-DbWorkspaceItemDetails -Path "/Users/user@example.com/project/ScaleExampleNotebook"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/get-status"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Import-DbWorkspaceItem
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
			Import-DbWorkspaceItem -Path "/myImportedFolder -Format "DBC" -LocalPath "C:\myFileToImport.dbc" -Overwrite $false
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
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/import"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader
	
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
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-DbWorkspaceItem
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
			Get-DbWorkspaceItem -Path "/"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/list"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function New-DbWorkspaceDirectory
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
			New-DbWorkspaceDirectory -Path "/myNewDirectory"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/workspace/mkdirs"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}