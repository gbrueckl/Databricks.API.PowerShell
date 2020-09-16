Function Add-DatabricksClusterLocalLibrary
{
	<#
		.SYNOPSIS
		Uploads a local library (.jar, .whl, ...) to DBFS and adds it to a cluster.
		.DESCRIPTION
		Retrieves the information for a cluster given its identifier. Clusters can be described while they are running, or up to 30 days after they are terminated.
		Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#get
		.PARAMETER ClusterID 
		The ID of the cluster on which you want to install the library.
		.PARAMETER LocalPath
		The local path where the library (.jar, .whl, ...) is located.
		.PARAMETER DBFSPath
		The DBFS path where to store the library file. Default is "/libraries/"
		.PARAMETER LibraryType
		By default, the LibraryType is derived from the file-extension of the LocalPath parametr. However, if you uploaded a zipped file, you need to set the Library Type explicitly!
		.EXAMPLE
		Add-DatabricksClusterLocalLibrary -ClusterID "1202-211320-brick1" -LocalPath "C:\myLibrary.jar"
	#>
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("local_path", "path")] [string] $LocalPath,
		[Parameter(Mandatory = $false)] [Alias("dbfs_path")] [string] $DBFSPath = "/libraries/",
		[Parameter(Mandatory = $false)] [Alias("library_type")] [string] [ValidateSet('jar', 'whl', 'egg', 'AUTO')]$LibraryType = "AUTO"
	)

	begin {
		
	}

	process {
		$localFile = Get-Item $LocalPath

		$dbfsFullPath = "/" + $DBFSPath.Trim("/") + "/" + $localFile.Name
		Write-Verbose "Uploading local library ($($localFile.FullName)) to DBFS ($dbfsFullPath) ..."
		$x = Upload-DatabricksFSFile -Path $dbfsFullPath -LocalPath $localFile.FullName -Overwrite $true

		Write-Verbose "Getting Cluster $ClusterID ..."
		$cluster = Get-DatabricksCluster -ClusterID $ClusterID
		
		# we can only add libraries to running clusters!
		if ($cluster.state -eq "TERMINATED") {
			Write-Warning "Cluster $($cluster.cluster_name) is in TERMINATED state and libraries can only be installed on running clusters!"
			Write-Verbose "Temporary starting cluster $($cluster.cluster_name) (ID: $($cluster.cluster_id)) to install latest libraries ..."
			Start-DatabricksCluster -ClusterID $cluster.cluster_id

			Write-Verbose "Waiting 10 seconds for cluster startup ..."
			Start-Sleep -Seconds 10
		}

		if($LibraryType -eq "AUTO")
		{
			Write-Verbose "Deriving LibraryType from filename ..."
			$LibraryType = $localFile.Extension.ToLower().Replace(".", "")
			Write-Verbose "    LibraryType from filename: $LibraryType"
		}

		$libraries = @(
			@{
				$LibraryType = "dbfs:$dbfsFullPath"
			}
		)
		Write-Verbose "Installing library '$($locaFile.Name)' on cluster $($cluster.cluster_name) (ID: $($cluster.cluster_id) ..."
		$result = Add-DatabricksClusterLibraries -ClusterID $cluster.cluster_id -Libraries $libraries
		Write-Verbose "Libraries installed!"

		Write-Verbose "Waiting 10 seconds for library installation ..."
		Start-Sleep -Seconds 10

		if ($cluster.state -eq "TERMINATED") {
			Write-Verbose "Terminating cluster $($cluster.cluster_name) (ID: $($cluster.cluster_id)) after installing libraries ..."
			Stop-DatabricksCluster -ClusterID $cluster.cluster_id		
		}
		
		return 
	}
}

#F unction Add-DatabricksWorkspaceLibrary {
	<#
			.SYNOPSIS
			Creates a new library in the Databricks Workspace similar to creating a notebook.
			.DESCRIPTION
			Creates a new library in the Databricks Workspace similar to creating a notebook.
			.PARAMETER ParentPath 
			Parent path in the Databricks workspace where the library should be created
			.PARAMETER LibraryName
			Name of the library to add.
			.PARAMETER LibraryType 
			Type of the library (PyPi, Maven, ...)
			.PARAMETER AutoAttach 
			Switch to make the library automatically attach to all existing and future clusters.
			.EXAMPLE
			$libraries = @(
							@{pypi = @{package = "numpy"}}
							@{jar = "dbfs:/mnt/libraries/library.jar" }
							)
			Add-DatabricksClusterLibraries -ClusterID "1234-211320-brick1" -Libraries $libraries

			
	#>
	<#
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)] [string] $ParentPath, 
		[Parameter(Mandatory = $true)] [string] $LibraryName,
		[Parameter(Mandatory = $true)] [string] $LibraryType,
		[Parameter(Mandatory = $false)] [switch] $AutoAttach
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/libraries/create"

	#Set parameters
	Write-Verbose "Building Body/Parameters for final API call ..."
	$parentWorkspaceItem = Get-DatabricksWorkspaceItem -Path $ParentPath

	$parameters = @{
		file = $LibraryName 
		name = $LibraryName 
		parentId = $parentWorkspaceItem.object_id
		library_type = $LibraryType
	}

	$parameters | Add-Property -Name "autoAttach" -Value $AutoAttach

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}
#>