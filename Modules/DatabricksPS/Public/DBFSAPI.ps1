Function Add-FSFile
{
	<#
			.SYNOPSIS
			Opens a stream to write to a file and returns a handle to this stream. There is a 10 minute idle timeout on this handle. If a file or directory already exists on the given path and overwrite is set to false, this call will throw an exception with RESOURCE_ALREADY_EXISTS. A typical workflow for file upload would be:
			.DESCRIPTION
			Opens a stream to write to a file and returns a handle to this stream. There is a 10 minute idle timeout on this handle. If a file or directory already exists on the given path and overwrite is set to false, this call will throw an exception with RESOURCE_ALREADY_EXISTS. A typical workflow for file upload would be:
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#create
			.PARAMETER Path 
			The path of the new file. The path should be the absolute DBFS path (e.g. "/mnt/foo.txt"). This field is required.
			.PARAMETER Overwrite 
			The flag that specifies whether to overwrite existing file/files.
			.EXAMPLE
			Add-FSFile -Path "/mnt/foo/" -Overwrite $false
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Overwrite = $false
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/create"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		overwrite = $Overwrite 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Add-FSFileBlock
{
	<#
			.SYNOPSIS
			Appends a block of data to the stream specified by the input handle. If the handle does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If the block of data exceeds 1 MB, this call will throw an exception with MAX_BLOCK_SIZE_EXCEEDED.
			.DESCRIPTION
			Appends a block of data to the stream specified by the input handle. If the handle does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If the block of data exceeds 1 MB, this call will throw an exception with MAX_BLOCK_SIZE_EXCEEDED.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#add-block
			.PARAMETER Handle 
			The handle on an open stream. This field is required.
			.PARAMETER Data 
			The base64-encoded data to append to the stream. This has a limit of 1 MB. This field is required.
			.EXAMPLE
			Add-FSFileBlock -Handle 7904256 -Data "ZGF0YWJyaWNrcwo="
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int] $Handle, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $Data
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/add-block"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		handle = $Handle 
		data = $Data 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Close-FSFile
{
	<#
			.SYNOPSIS
			Closes the stream specified by the input handle. If the handle does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST.
			.DESCRIPTION
			Closes the stream specified by the input handle. If the handle does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#close
			.PARAMETER Handle 
			The handle on an open stream. This field is required.
			.EXAMPLE
			Close-FSFile -Handle 7904256
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int] $Handle
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/close"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		handle = $Handle 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Remove-FSFile
{
	<#
			.SYNOPSIS
			Delete the file or directory (optionally recursively delete all files in the directory). This call will throw an exception with IO_ERROR if the path is a non-empty directory and recursive is set to false or on other similar errors.
			.DESCRIPTION
			Delete the file or directory (optionally recursively delete all files in the directory). This call will throw an exception with IO_ERROR if the path is a non-empty directory and recursive is set to false or on other similar errors.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#delete
			.PARAMETER Path 
			The path of the file or directory to delete. The path should be the absolute DBFS path (e.g. "/mnt/foo/"). This field is required.
			.PARAMETER Recursive 
			Whether or not to recursively delete the directory's contents. Deleting empty directories can be done without providing the recursive flag.
			.EXAMPLE
			Remove-FSFile -Path "/MyFolder" -Recursive $false
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Recursive = $false
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

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

Function Get-FSItem
{
	<#
			.SYNOPSIS
			Gets the file information of a file or directory. If the file or directory does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST.
			.DESCRIPTION
			Gets the file information of a file or directory. If the file or directory does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#get-status
			.PARAMETER Path 
			The path of the file or directory. The path should be the absolute DBFS path (e.g. "/mnt/foo/"). This field is required.
			.PARAMETER ChildItems 
			Defines whether information of the item or its child items are returned. This field is not required. Default is 'false'.
			.EXAMPLE
			Get-DatabricksFSItem -Path "/myFolder/myFile"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path,
		[Parameter(Mandatory = $false, Position = 2)] [bool] $ChildItems = $false
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	if($ChildItems)
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/list"
	}
	else
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/get-status"
	}
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Add-FSDirectory
{
	<#
			.SYNOPSIS
			Creates the given directory and necessary parent directories if they do not exist. If there exists a file (not a directory) at any prefix of the input path, this call will throw an exception with RESOURCE_ALREADY_EXISTS. Note that if this operation fails it may have succeeded in creating some of the necessary parent directories.
			.DESCRIPTION
			Creates the given directory and necessary parent directories if they do not exist. If there exists a file (not a directory) at any prefix of the input path, this call will throw an exception with RESOURCE_ALREADY_EXISTS. Note that if this operation fails it may have succeeded in creating some of the necessary parent directories.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#mkdirs
			.PARAMETER Path 
			The path of the new directory. The path should be the absolute DBFS path (e.g. "/mnt/foo/"). This field is required.
			.EXAMPLE
			Add-FSDirectory -Path "/myNewFolder"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/dbfs/mkdirs"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}