Function Add-DatabricksSQLEndpoint {
  <#
			.SYNOPSIS
			Create a SQL endpoint.
			.DESCRIPTION
			Create a SQL endpoint.
			Official API Documentation: https://docs.databricks.com/sql/api/sql-endpoints.html
			.PARAMETER Name 
			Name of the SQL endpoint. Must be unique. This field is required.
      .PARAMETER ClusterSize 
			The size of the clusters allocated to the endpoint: "2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large". For the mapping from cluster to instance size, see Cluster size. This field is required.
      .PARAMETER MinNumClusters
			Minimum number of clusters available when a SQL endpoint is running. The default is 1.
      .PARAMETER MaxNumClusters 
			Maximum number of clusters available when a SQL endpoint is running. This field is required. If multi-cluster load balancing is not enabled, this is limited to 1.
      .PARAMETER AutoStopMinutes 
			Time in minutes until an idle SQL endpoint terminates all clusters and stops. This field is optional. The default is 0, which means auto stop is disabled.
			.PARAMETER Tags 
			An object containing a set of tags for endpoint resources. Azure Databricks tags all endpoint resources with these tags. This field is optional.
			.PARAMETER EnablePhoton 
			Whether to enable Photon. This field is optional.
			.EXAMPLE
			Add-DatabricksSQLEndpoint -Name "My SQL Endpoint" -ClusterSize "Medium" -MinNumclusters 1 -MaxNumclusters 10 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("endpoint_name")] [string] $Name,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_size")] [ValidateSet("2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large")] [string] $ClusterSize,
    [Parameter(Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)] [Alias("min_num_clusters")] [int] $MinNumClusters,
    [Parameter(Mandatory = $true, Position = 4, ValueFromPipelineByPropertyName = $true)] [Alias("max_num_clusters")] [int] $MaxNumClusters,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("auto_stop_mins")] [int] $AutoStopMinutes,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [object] $Tags,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_photon")] [Nullable[bool]] $EnablePhoton
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{
      name = $Name
      cluster_size = $ClusterSize
      min_num_clusters = $MinNumClusters
      max_num_clusters = $MaxNumClusters
    }

    if($PSBoundParameters.ContainsKey('AutoStopMinutes'))
    {
      $parameters | Add-Property -Name "auto_stop_mins" -Value $AutoStopMinutes
    }
    if($PSBoundParameters.ContainsKey('Tags'))
    {
      $parameters | Add-Property -Name "tags" -Value $tags
    }
    if($PSBoundParameters.ContainsKey('EnablePhoton'))
    {
      $parameters | Add-Property -Name "enable_photon" -Value $EnablePhoton
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Remove-DatabricksSQLEndpoint {
  <#
      .SYNOPSIS
      Delete a SQL endpoint.
      .DESCRIPTION
      Delete a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#delete
      .PARAMETER SQLEndpointId 
      ID of the SQL endpoint you want to delete.
      .EXAMPLE
      Remove-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointId
  )
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointId"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Update-DatabricksSQLEndpoint {
  <#
			.SYNOPSIS
			Modify a SQL endpoint. All fields are optional. Missing fields default to the current values.
			.DESCRIPTION
			Modify a SQL endpoint. All fields are optional. Missing fields default to the current values.
			Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#edit
      .PARAMETER SQLEndpointId 
			ID of the SQL endpoint.This field is required.
			.PARAMETER Name 
			Name of the SQL endpoint.
      .PARAMETER ClusterSize 
			The size of the clusters allocated to the endpoint: "2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large". For the mapping from cluster to instance size, see Cluster size. 
      .PARAMETER MinNumClusters
			Minimum number of clusters available when a SQL endpoint is running.
      .PARAMETER MaxNumClusters 
			Maximum number of clusters available when a SQL endpoint is running. If multi-cluster load balancing is not enabled, this is limited to 1.
      .PARAMETER AutoStopMinutes 
			Time in minutes until an idle SQL endpoint terminates all clusters and stops. The default is 0, which means auto stop is disabled.
			.PARAMETER Tags 
			An object containing a set of tags for endpoint resources. Azure Databricks tags all endpoint resources with these tags. 
			.PARAMETER EnablePhoton 
			Whether to enable Photon. 
			.EXAMPLE
			Add-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef" -Name "My updated SQL Endpoint" -ClusterSize "Large" -MinNumclusters 2 -MaxNumclusters 8 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointId,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("endpoint_name")] [string] $Name,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_size")] [ValidateSet("2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large")] [string] $ClusterSize,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("min_num_clusters")] [int] $MinNumClusters,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("max_num_clusters")] [int] $MaxNumClusters,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("auto_stop_mins")] [int] $AutoStopMinutes,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [object] $Tags,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_photon")] [Nullable[bool]] $EnablePhoton
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {

    $apiEndpoint += "/$SQLEndpointId"

    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{}

    $parameters | Add-Property -Name "Name" -Value $Name
    $parameters | Add-Property -Name "cluster_size" -Value $ClusterSize
    $parameters | Add-Property -Name "min_num_clusters" -Value $MinNumClusters
    $parameters | Add-Property -Name "max_num_clusters" -Value $MaxNumClusters
    $parameters | Add-Property -Name "auto_stop_mins" -Value $AutoStopMinutes
    $parameters | Add-Property -Name "tags" -Value $tags
    $parameters | Add-Property -Name "enable_photon" -Value $EnablePhoton

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Get-DatabricksSQLEndpoint {
  <#
      .SYNOPSIS
      List all SQL endpoints in the workspace or Retrieve the info for a SQL endpoint.
      .DESCRIPTION
      Delete a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#get and https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#list
      .PARAMETER SQLEndpointId 
      ID of the SQL endpoint you want to delete
      .EXAMPLE
      Get-DatabricksSQLEndpoint
      .EXAMPLE
      Get-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef"
      .EXAMPLE
      Get-DatabricksSQLEndpoint | Get-DatabricksSQLEndpoint
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointId
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if($PSBoundParameters.ContainsKey('SQLEndpointId'))
    {
      $apiEndpoint += "/$SQLEndpointId"
    }

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    
    if($PSBoundParameters.ContainsKey('SQLEndpointId'))
    {
      return $result
    }
    else {
      return $result.endpoints
    }
  }
}


Function Start-DatabricksSQLEndpoint {
  <#
      .SYNOPSIS
      Start a SQL endpoint.
      .DESCRIPTION
      Start a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#start
      .PARAMETER SQLEndpointId 
      ID of the SQL endpoint you want to start.
      .EXAMPLE
      Start-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointId
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointId/start"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Stop-DatabricksSQLEndpoint {
  <#
      .SYNOPSIS
      Stop a SQL endpoint.
      .DESCRIPTION
      Stop a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#stop
      .PARAMETER SQLEndpointId 
      ID of the SQL endpoint you want to stop.
      .EXAMPLE
      Stop-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointId
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointId/stop"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Get-DatabricksSQLEndpointConfig {
  <#
      .SYNOPSIS
      Get the configuration for all SQL endpoints.
      .DESCRIPTION
      Get the configuration for all SQL endpoints.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#get-1
      .PARAMETER SQLEndpointId 
      ID of the SQL endpoint you want to delete
      .EXAMPLE
      Get-DatabricksSQLConfig
  #>
  [CmdletBinding()]
  param ()
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/config/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Update-DatabricksSQLEndpointConfig {
  <#
			.SYNOPSIS
			Edit the configuration for all SQL endpoints. All fields are required. Invoking this method restarts all running SQL endpoints.
			.DESCRIPTION
			Edit the configuration for all SQL endpoints. All fields are required. Invoking this method restarts all running SQL endpoints.
			Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#edit-1
      .PARAMETER SQLEndpointId 
			ID of the SQL endpoint.This field is required.
			.EXAMPLE
			Add-DatabricksSQLEndpoint -SQLEndpointId "0123456789abcdef" -Name "My updated SQL Endpoint" -ClusterSize "Large" -MinNumclusters 2 -MaxNumclusters 8 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("security_policy")] [ValidateSet("DATA_ACCESS_CONTROL", "PASSTHROUGH")] [string] $SecurityPolicy,
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("data_access_config")] [hashtable] $DataAccessConfig,
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("instance_profile_arn")] [object] $InstanceProfileARN,
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("pass_through", "passthrough")] [object] $CredentialPassThrough,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
  )
	
  begin {
    $requestMethod = "PUT"
    $apiEndpoint = "/2.0/sql/config/endpoints"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if(-not $Force)
    {
      Write-Error "This cmdlet will restart all running SQL endpoints. If you want to proceed, please use the -Force parameter!"
      return
    }

    #Set parameters
    $parameters = @{
      security_policy = $SecurityPolicy
    }

    $parameters | Add-Property -Name "data_access_config" -Value $DataAccessConfig
    $parameters | Add-Property -Name "instance_profile_arn" -Value $InstanceProfileARN

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}