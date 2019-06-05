Function Remove-DatabricksWorkspaceItem 
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
			Remove-DatabricksWorkspaceItem -Path <Path> -Recursive $false
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Recursive
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/workspace/delete"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		recursive = $Recursive 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}
				
Function Export-DatabricksWorkspaceItem
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
			.PARAMETER CreateFolder 
			Use if the local folder should be created if it does not exist yet
			.EXAMPLE
			Export-WorkspaceItem -Path "/" -LocalPath "C:\myExport.dbc" -Format "DBC"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [string] $Path, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $LocalPath, 
		[Parameter(Mandatory = $false, Position = 3)] [string] [ValidateSet("SOURCE", "HTML", "JUPYTER", "DBC")] $Format = "SOURCE",
		[Parameter(Mandatory = $false, Position = 4)] [switch] $CreateFolder
	)
	
	begin	{ 
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/workspace/export"
	}
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			path = $Path 
			format = $Format  
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
				
		Write-Verbose "Converting Base64 encoded content to Byte-Array ..."
		$exportBytes = [Convert]::FromBase64String($result.content)
	
		if($CreateFolder)
		{
			$localFolder = Split-Path $LocalPath -Parent
			Write-Verbose "Checking if Folder '$localFolder' exists ..."
			if(-not (Test-Path $localFolder))
			{
				Write-Verbose "Creating local folder '$localFolder' ..."
				$x = New-Item -ItemType Directory -Force -Path $localFolder
			}
		}
	
		Write-Verbose "Writing binary content ($($exportBytes.Length) bytes) to  $LocalPath ..."
		[IO.File]::WriteAllBytes($LocalPath, $exportBytes)
	}
}


Function Import-DatabricksWorkspaceItem
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
		[Parameter(Mandatory = $true, Position = 4, ValueFromPipelineByPropertyName = $true)] [string] $LocalPath, 
		[Parameter(Mandatory = $false, Position = 5)] [bool] $Overwrite = $false
	)
	
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/workspace/import"
	}
	process {	
		Write-Verbose "Reading content from $LocalPath ..."
		$fileBytes = [IO.File]::ReadAllBytes($LocalPath)
		Write-Verbose "Converting content to Base64 string ..."
		$content = [Convert]::ToBase64String($fileBytes)
	
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			path = $Path 
			format = $Format 
			language = $Language 
			content = $Content 
			overwrite = $Overwrite 
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}


Function Get-DatabricksWorkspaceItem
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
			Get-DatabricksWorkspaceItem -Path "/"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [string] $Path,
		[Parameter(Mandatory = $false, Position = 2)] [switch] $ChildItems
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/workspace/get-status"
		if($ChildItems)
		{
			$apiEndpoint = "/2.0/workspace/list"
		}
	}

	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			path = $Path 
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if($ChildItems)
		{
			return $result.objects
		}
		else
		{
			return $result
		}
	}
}


Function Add-DatabricksWorkspaceDirectory
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
			Add-DatabricksWorkspaceDirectory -Path "/myNewDirectory"
	#>
	[Alias("New-WorkspaceDirectory")]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [string] $Path
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/workspace/mkdirs"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			path = $Path 
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}