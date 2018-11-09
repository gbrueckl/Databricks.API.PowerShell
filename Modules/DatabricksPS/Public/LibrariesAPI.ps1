#requires -Version 3.0
Function Get-ClusterLibraries
{
	<#
			.SYNOPSIS
			Get the status of libraries on a cluster or all clusters. A status will be available for all libraries installed on the cluster via the API or the libraries UI as well as libraries set to be installed on all clusters via the libraries UI. If a library has been set to be installed on all clusters, is_library_for_all_clusters will be true, even if the library was also installed on the cluster.
			.DESCRIPTION
			Get the status of libraries on a cluster or all clusters. A status will be available for all libraries installed on the cluster via the API or the libraries UI as well as libraries set to be installed on all clusters via the libraries UI. If a library has been set to be installed on all clusters, is_library_for_all_clusters will be true, even if the library was also installed on the cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#cluster-status
			Official API Documentation: https://docs.databricks.com/api/latest/libraries.html#all-cluster-statuses
			.PARAMETER Cluster_Id 
			Unique identifier of the cluster whose status should be retrieved. This field is not required.
			.EXAMPLE
			Get-ClusterLibrary -ClusterID "1202-211320-brick1"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [string] $ClusterID = $null
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/libraries/all-cluster-statuses"
	if($ClusterID)
	{
		Write-Verbose "ClusterID specified ($ClusterID) - using cluster-status endpoint instead of all-cluster-statuses ..."
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/libraries/cluster-status"
	}
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{}
	$parameters | Add-Property  -Name "cluster_id" -Value $ClusterID
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Add-ClusterLibraries
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
			The libraries to install.
			.EXAMPLE
			Add-ClusterLibraries -ClusterID <cluster_id> -Libraries <libraries>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $true, Position = 2)] [hashtable[]] $Libraries
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/libraries/install"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		cluster_id = $ClusterID 
		libraries = $Libraries 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Remove-ClusterLibraries
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
			The libraries to uninstall.
			.EXAMPLE
			Remove-ClusterLibraries -ClusterID <cluster_id> -Libraries <libraries>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $true, Position = 2)] [hashtable[]] $Libraries
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/libraries/uninstall"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		cluster_id = $ClusterID 
		libraries = $Libraries 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}