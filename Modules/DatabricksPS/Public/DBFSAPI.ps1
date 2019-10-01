Function Add-DatabricksFSFile
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
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile1.txt" -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			.EXAMPLE
			#AUTOMATED_TEST:Add empty file
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile1.txt" -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			.EXAMPLE
			#AUTOMATED_TEST:Add new file with content and close it
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile2.txt" -Overwrite $true
			Add-DatabricksFSFileBlock -Handle $newFile.handle -Data "This is a plaintext!" -AsPlainText
			Close-DatabricksFSFile -Handle $newFile.handle
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Overwrite = $false
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/create"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		overwrite = $Overwrite 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Add-DatabricksFSFileBlock
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
			.PARAMETER AsPlainText
			If specified, Data is interpreted as plain text and encoded to Base64 internally before the upload.
			.EXAMPLE
			Add-DatabricksFSFileBlock -Handle 7904256 -Data "ZGF0YWJyaWNrcwo="
			#AUTOMATED_TEST:Add new file with content and close it
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile2.txt" -Overwrite $true
			Add-DatabricksFSFileBlock -Handle $newFile.handle -Data "This is a plaintext!" -AsPlainText
			Close-DatabricksFSFile -Handle $newFile.handle
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int] $Handle, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $Data,
		[Parameter(Mandatory = $false, Position = 2)] [switch] $AsPlainText
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/add-block"

	if($AsPlainText)
	{
		$Data = $Data | ConvertTo-Base64 -Encoding ([Text.Encoding]::UTF8)
	}
	
	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		handle = $Handle 
		data = $Data 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Close-DatabricksFSFile
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
			Close-DatabricksFSFile -Handle 7904256
			#AUTOMATED_TEST:Add and close empty file
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile1.txt" -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			.EXAMPLE
			#AUTOMATED_TEST:Add new file with content and close it
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile2.txt" -Overwrite $true
			Add-DatabricksFSFileBlock -Handle $newFile.handle -Data "This is a plaintext!" -AsPlainText
			Close-DatabricksFSFile -Handle $newFile.handle
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int] $Handle
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/close"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		handle = $Handle 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Remove-DatabricksFSItem
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
			Remove-DatabricksFSItem -Path "/MyFolder" -Recursive $false
			.EXAMPLE
			#AUTOMATED_TEST:Add and remove File
			$filePath = "/myTestFolder/myFile1.txt"
			$newFile = Add-DatabricksFSFile -Path $filePath -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			Remove-DatabricksFSItem -Path $filePath
			.EXAMPLE
			#AUTOMATED_TEST:Add and remove folder
			$folderPath = "/myTestFolder/myFolder"
			Add-DatabricksFSDirectory -Path $folderPath
			Remove-DatabricksFSItem -Path $folderPath
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [bool] $Recursive = $false
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/delete"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
		recursive = $Recursive 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Get-DatabricksFSItem
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
			.EXAMPLE
			#AUTOMATED_TEST:Get single file
			$filePath = "/myTestFolder/myFile1.txt"
			$newFile = Add-DatabricksFSFile -Path $filePath -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			Get-DatabricksFSItem -Path $filePath
			.EXAMPLE
			#AUTOMATED_TEST:Get single folder
			$folderPath = "/myTestFolder/"
			Get-DatabricksFSItem -Path $folderPath
			.EXAMPLE
			#AUTOMATED_TEST:Add and remove folder
			$folderPath = "/myTestFolder/"
			Add-DatabricksFSDirectory -Path $folderPath
			Get-DatabricksFSItem -Path $folderPath -ChildItems
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path,
		[Parameter(Mandatory = $false, Position = 2)] [switch] $ChildItems
	)
	
	$requestMethod = "GET"
	$apiEndpoint = "/2.0/dbfs/get-status"
	if($ChildItems)
	{
		$apiEndpoint = "/2.0/dbfs/list"
	}
		

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	if($ChildItems){
		# if -ChildItems was specified, we return the files as an array
		return $result.files
	}
	else
	{
		# if -ChildItems was not specified, we return the result as it is (a single file)
		return $result
	}
}

Function Add-DatabricksFSDirectory
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
			Add-DatabricksFSDirectory -Path "/myNewFolder"
			.EXAMPLE
			#AUTOMATED_TEST:Add a folder
			$folderPath = "/myTestFolder/myFolder2"
			Add-DatabricksFSDirectory -Path $folderPath
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/mkdirs"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Move-DatabricksFSItem
{
	<#
			.SYNOPSIS
			Move a file from one location to another location within DBFS. If the source file does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If there already exists a file in the destination path, this call will throw an exception with RESOURCE_ALREADY_EXISTS. If the given source path is a directory, this call will always recursively move all files.
			.DESCRIPTION
			Move a file from one location to another location within DBFS. If the source file does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If there already exists a file in the destination path, this call will throw an exception with RESOURCE_ALREADY_EXISTS. If the given source path is a directory, this call will always recursively move all files.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#move
			.PARAMETER SourcePath 
			The source path of the file or directory. The path should be the absolute DBFS path (e.g. "/mnt/foo/"). This field is required.
			.PARAMETER DestinationPath 
			The destination path of the file or directory. The path should be the absolute DBFS path (e.g. "/mnt/bar/"). This field is required.
			.EXAMPLE
			Move-DatabricksFSItem -SourcePath "/myFile.csv" -DestinationPath "/myFiles/myCSV.csv"
			.EXAMPLE
			#AUTOMATED_TEST:Move single file
			$sourcePath = "/myTestFolder/myFile1.txt"
			$targetPath = "/myTestFolder/myMovedFile.txt"
			$newFile = Add-DatabricksFSFile -Path $sourcePath -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
			Remove-DatabricksFSItem -Path $targetPath -ErrorAction SilentlyContinue
			Move-DatabricksFSItem -SourcePath $sourcePath -DestinationPath $targetPath
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $SourcePath, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $DestinationPath
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/dbfs/move"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		source_path = $SourcePath 
		destination_path = $DestinationPath 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Get-DatabricksFSContent
{
	<#
			.SYNOPSIS
			Returns the contents of a file. If the file does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If the path is a directory, the read length is negative, or if the offset is negative, this call will throw an exception with INVALID_PARAMETER_VALUE. If the read length exceeds 1 MB, this call will throw an exception with MAX_READ_SIZE_EXCEEDED. If offset + length exceeds the number of bytes in a file, we will read contents until the end of file.
			.DESCRIPTION
			Returns the contents of a file. If the file does not exist, this call will throw an exception with RESOURCE_DOES_NOT_EXIST. If the path is a directory, the read length is negative, or if the offset is negative, this call will throw an exception with INVALID_PARAMETER_VALUE. If the read length exceeds 1 MB, this call will throw an exception with MAX_READ_SIZE_EXCEEDED. If offset + length exceeds the number of bytes in a file, we will read contents until the end of file.
			Official API Documentation: https://docs.databricks.com/api/latest/dbfs.html#read
			.PARAMETER Path 
			The path of the file to read. The path should be the absolute DBFS path (e.g. "/mnt/foo/"). This field is required.
			.PARAMETER Offset 
			The offset to read from in bytes.
			.PARAMETER Length 
			The number of bytes to read starting from the offset. This has a limit of 1 MB, and a default value of 0.5 MB.
			.PARAMETER Decode
			Adds a new property to the result that contains the decoded string value.
			.EXAMPLE
			Get-DatabricksFSContent -Path "/myFile.csv"
			.EXAMPLE
			#AUTOMATED_TEST:Get file content
			$content = "This is my test content!"
			$filePath = "/myTestFolder/myFile1.txt"
			$newFile = Add-DatabricksFSFile -Path $filePath -Overwrite $true
			Add-DatabricksFSFileBlock -Handle $newFile.handle -Data $content -AsPlainText
			Close-DatabricksFSFile -Handle $newFile.handle
			$readContent = Get-DatabricksFSContent -Path $filePath -Decode
			if($readContent.data_decoded -ne $content) { throw "Read content does not match written content!" }
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 2)] [int] $Offset = -1, 
		[Parameter(Mandatory = $false, Position = 3)] [int] $Length = -1,
		[Parameter(Mandatory = $false, Position = 4)] [switch] $Decode
	)
	
	$requestMethod = "GET"
	$apiEndpoint = "/2.0/dbfs/read"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = $Path 
	}

	$parameters | Add-Property -Name "offset" -Value $Offset -NullValue -1
	$parameters | Add-Property -Name "length" -Value $Length -NullValue -1
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	if($Decode)
	{
		Write-Verbose "Decoding data ..."
		$decodedValue = $result.data | ConvertFrom-Base64 -Encoding ([Text.Encoding]::UTF8)
		Write-Verbose "Adding decoded data to result ..."
		Add-Member -InputObject $result -MemberType NoteProperty -Name "data_decoded" -Value $decodedValue
	}
	
	return $result
}




Function Upload-DatabricksFSFile
{
	<#
			.SYNOPSIS
			Uploads a local file to the Databricks File System (DBFS)
			.DESCRIPTION
			Uploads a local file to the Databricks File System (DBFS).
			This cmdlet is basically a combination of Add-DatabricksFSFile, Add-DatabricksFSFileContent and Close-DatabricksFSFile.
			.PARAMETER Path 
			The path of the new file to be created in DBFS. The path should be the absolute DBFS path (e.g. "/mnt/foo.txt"). This field is required.
			.PARAMETER LocalPath 
			The path of the local file to be uploaded.
			.PARAMETER Overwrite 
			The flag that specifies whether to overwrite existing file/files.
			.PARAMETER BatchSize 
			The BatchSize to use when uploading the data
			.EXAMPLE
			Upload-DatabricksFSFile -Path '/DatabricksPS_Tests/test1.txt' -LocalPath ".\test1.txt" -Overwrite $true -Verbose -BatchSize 1000
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $LocalPath,
		[Parameter(Mandatory = $false, Position = 3)] [bool] $Overwrite = $false,
		[Parameter(Mandatory = $false, Position = 4)] [int] $BatchSize = 1048000
	)
	
	Write-Verbose "Creating new file in DBFS at $Path ..."
	$dbfsFile = Add-DatabricksFSFile -Path $Path -Overwrite $Overwrite
	
	Write-Verbose "Reading content from $LocalPath ..."
	$localFile = [System.IO.File]::ReadAllBytes($LocalPath)
	$totalSize = $localFile.Length
	
	Write-Verbose "Starting upload of file in batches of size $BatchSize ..."
	$offset = 0
	do
	{
		Write-Verbose "Adding new content from offset $offset ..."
		if($offset + $BatchSize -gt $totalSize)
		{
			$BatchSize = $totalSize - $offset
		}
		$content = $localFile[$offset..$($offset + $BatchSize)]
		$contentB64 = [System.Convert]::ToBase64String($content)
		
		Add-DatabricksFSFileBlock -Handle $dbfsFile.handle -Data $contentB64
		
		$offset = $offset + $BatchSize + 1
	}
	while($offset -lt $totalSize)
	Write-Verbose "Finished uploading local file '$LocalPath' to DBFS '$Path'"
	
	Close-DatabricksFSFile -Handle $dbfsFile.handle
	
	return $Path
}



Function Download-DatabricksFSFile
{
	<#
			.SYNOPSIS
			Downloads a file from the Databricks File System (DBFS) to the local file system.
			.DESCRIPTION
			Downloads a file from the Databricks File System (DBFS) to the local file system.
			This cmdlet subsequently calls Get-DatabricksFSContent until the whole file is downloaded
			.PARAMETER Path 
			The path of the file in DBFS that should be downloaded. The path should be the absolute DBFS path (e.g. "/mnt/foo.txt"). This field is required.
			.PARAMETER LocalPath 
			The path where the downloaded file is stored locally.
			.PARAMETER Overwrite 
			The flag that specifies whether to overwrite existing file/files.
			.PARAMETER BatchSize 
			The BatchSize to use when uploading the data
			.EXAMPLE
			Download-DatabricksFSFile -Path '/DatabricksPS_Tests/test1.txt' -LocalPath ".\test1.txt" -Overwrite $true -Verbose -BatchSize 1000
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $LocalPath,
		[Parameter(Mandatory = $false, Position = 3)] [bool] $Overwrite = $false,
		[Parameter(Mandatory = $false, Position = 4)] [int] $BatchSize = 1048576
	)
	
	$dbfsFile = Get-DatabricksFSItem -Path $Path
	
	if($dbfsFile.is_dir)
	{
		Write-Error "The specified path is a directory and not a file!"
	}
	
	if((Test-Path $LocalPath) -and $Overwrite)
	{
		Remove-Item $LocalPath -Force
	}
	
	$totalSize = $dbfsFile.file_size # number of bytes of the original file!
	
	Write-Verbose "Starting download of file in batches of size $BatchSize ..."
	Set-Content -Path $LocalPath -Value @() -Encoding Byte 
	$offset = 0
	do
	{
		Write-Verbose "Downloading new content from offset $offset ..."
		$dbfsFileContent = Get-DatabricksFSContent -Path $dbfsFile.path -Offset $offset -Length $BatchSize
		$dbfsByteContent = [System.Convert]::FromBase64String($dbfsFilecontent.data)
		
		Add-Content -Path $LocalPath -Value $dbfsByteContent -Encoding Byte -ErrorAction Stop
		
		$offset = $offset + $BatchSize
	} while ($offset -lt $totalSize)	
	Write-Verbose "Finished downloading DBFS file '$Path' to local file '$LocalPath'"
		
	return $LocalPath
}