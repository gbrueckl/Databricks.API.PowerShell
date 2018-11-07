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
			Close-FSFile -Handle <handle>
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