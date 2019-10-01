Function Get-DatabricksClusterLibraries
{
	<#
			.SYNOPSIS
			Get the status of libraries on a cluster or all clusters. A status will be available for all libraries installed on the cluster via the API or the libraries UI as well as libraries set to be installed on all clusters via the libraries UI. If a library has been set to be installed on all clusters, is_library_for_all_clusters will be true, even if the library was also installed on the cluster.
			.DESCRIPTION
			Get the status of libraries on a cluster or all clusters. A status will be available for all libraries installed on the cluster via the API or the libraries UI as well as libraries set to be installed on all clusters via the libraries UI. If a library has been set to be installed on all clusters, is_library_for_all_clusters will be true, even if the library was also installed on the cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#cluster-status
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#all-cluster-statuses
			.PARAMETER ClusterID 
			Unique identifier of the cluster whose status should be retrieved. This field is not required.
			.EXAMPLE
			Get-DatabricksClusterLibraries -ClusterID "1234-211320-brick1"
			.EXAMPLE
			Get-DatabricksClusterLibraries
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [string] $ClusterID = $null
	)

	$requestMethod = "GET"
	$apiEndpoint = "/2.0/libraries/all-cluster-statuses"
	if($ClusterID)
	{
		Write-Verbose "ClusterID specified ($ClusterID) - using cluster-status endpoint instead of all-cluster-statuses ..."
		$apiEndpoint = "/2.0/libraries/cluster-status"
	}

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{}
	$parameters | Add-Property  -Name "cluster_id" -Value $ClusterID
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	if($ClusterID)
	{
		# if a ClusterID was specified, we return the result as it is
		return $result
	}
	else
	{
		# if no ClusterID was specified, we return the statuses as an array
		return $result.statuses
	}
}

Function Add-DatabricksClusterLibraries
{
	<#
			.SYNOPSIS
			Install libraries on a cluster. The installation is asynchronous - it happens in the background after the completion of this request. The actual set of libraries to be installed on a cluster is the union of the libraries specified via this method and the libraries set to be installed on all clusters via the libraries UI.
			.DESCRIPTION
			Install libraries on a cluster. The installation is asynchronous - it happens in the background after the completion of this request. The actual set of libraries to be installed on a cluster is the union of the libraries specified via this method and the libraries set to be installed on all clusters via the libraries UI.
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#install
			.PARAMETER ClusterID 
			Unique identifier for the cluster on which to install these libraries. This field is required.
			.PARAMETER Libraries 
			The libraries to install. See https://docs.databricks.com/api/latest/libraries.html#install for details
			.EXAMPLE
			$libraries = @(
							@{pypi = @{package = "numpy"}}
							@{jar = "dbfs:/mnt/libraries/library.jar" }
							)
			Add-DatabricksClusterLibraries -ClusterID "1234-211320-brick1" -Libraries $libraries

			.EXAMPLE
			$libraries = '[
							{
							  "jar": "dbfs:/mnt/libraries/library.jar"
							},
							{
							  "egg": "dbfs:/mnt/libraries/library.egg"
							}
						  ]' | ConvertFrom-Json
			Add-DatabricksClusterLibraries -ClusterID "1234-211320-brick1" -Libraries $libraries
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $true, Position = 2)] [object[]] $Libraries
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/libraries/install"

	#Set parameters
	Write-Verbose "Building Body/Parameters for final API call ..."
	$parameters = @{
		cluster_id = $ClusterID 
		libraries = $Libraries 
	}

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Remove-DatabricksClusterLibraries
{
	<#
			.SYNOPSIS
			Set libraries to be uninstalled on a cluster. The libraries aren't uninstalled until the cluster is restarted. Uninstalling libraries that are not installed on the cluster has no impact but is not an error.
			.DESCRIPTION
			Set libraries to be uninstalled on a cluster. The libraries aren't uninstalled until the cluster is restarted. Uninstalling libraries that are not installed on the cluster has no impact but is not an error.
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#uninstall
			.PARAMETER ClusterID 
			Unique identifier for the cluster on which to uninstall these libraries. This field is required.
			.PARAMETER Libraries 
			The libraries to uninstall. See https://docs.databricks.com/api/latest/libraries.html#uninstall for details
			.EXAMPLE
			$libraries = @(
							@{pypi = @{package = "numpy"}}
							@{jar = "dbfs:/mnt/libraries/library.jar" }
							)
			Remove-DatabricksClusterLibraries -ClusterID "1234-211320-brick1" -Libraries $libraries

			.EXAMPLE
			$libraries = '[
							{
							  "jar": "dbfs:/mnt/libraries/library.jar"
							},
							{
							  "egg": "dbfs:/mnt/libraries/library.egg"
							}
						  ]' | ConvertFrom-Json
			Remove-DatabricksClusterLibraries -ClusterID "1234-211320-brick1" -Libraries $libraries
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $true, Position = 2)] [object[]] $Libraries
	)
	
	$requestMethod = "POST"
	$apiEndpoint = "/2.0/libraries/uninstall"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		cluster_id = $ClusterID 
		libraries = $Libraries 
	}

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}