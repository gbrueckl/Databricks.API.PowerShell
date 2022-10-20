Function Add-DatabricksSQLWarehouse {
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
      .PARAMETER EnableServerlessCompute
			Whether to enable Serverles. 
      .PARAMETER Channel
			Whether to use preview-featueres or not. 
      .PARAMETER SpotInstancePolicy
			What type of Spot instances to use - Cost-Optimized or Reliability-Optimized
			.EXAMPLE
			Add-DatabricksSQLWarehouse -Name "My SQL Endpoint" -ClusterSize "Medium" -MinNumclusters 1 -MaxNumclusters 10 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("endpoint_name")] [string] $Name,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_size")] [ValidateSet("2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large")] [string] $ClusterSize,
    [Parameter(Mandatory = $false, Position = 3, ValueFromPipelineByPropertyName = $true)] [Alias("min_num_clusters")] [int] $MinNumClusters = 1,
    [Parameter(Mandatory = $false, Position = 4, ValueFromPipelineByPropertyName = $true)] [Alias("max_num_clusters")] [int] $MaxNumClusters = 1,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("auto_stop_mins")] [int] $AutoStopMinutes = 60,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [object] $Tags,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_photon")] [Nullable[bool]] $EnablePhoton,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_serverless_compute")] [Nullable[bool]] $EnableServerlessCompute,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [ValidateSet("CHANNEL_NAME_PREVIEW", "CHANNEL_NAME_CURRENT")] [string] $Channel = "CHANNEL_NAME_CURRENT",
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("spot_instance_policy")] [ValidateSet("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED")] [string] $SpotInstancePolicy
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{
      name         = $Name
      cluster_size = $ClusterSize
    }

    $parameters | Add-Property -Name "min_num_clusters" -Value $MinNumClusters
    $parameters | Add-Property -Name "max_num_clusters" -Value $MaxNumClusters

    if ($PSBoundParameters.ContainsKey('AutoStopMinutes')) {
      $parameters | Add-Property -Name "auto_stop_mins" -Value $AutoStopMinutes
    }
    if ($PSBoundParameters.ContainsKey('Tags')) {
      $parameters | Add-Property -Name "tags" -Value @{custom_tags = ConvertTo-KeyValueArray $tags }
    }
    if ($PSBoundParameters.ContainsKey('EnablePhoton')) {
      $parameters | Add-Property -Name "enable_photon" -Value $EnablePhoton
    }
    if ($PSBoundParameters.ContainsKey('EnableServerlessCompute')) {
      $parameters | Add-Property -Name "enable_serverless_compute" -Value $EnableServerlessCompute
    }
    if ($PSBoundParameters.ContainsKey('Channel')) {
      $parameters | Add-Property -Name "channel" -Value @{name = $Channel }
    }
    if ($PSBoundParameters.ContainsKey('SpotInstancePolicy')) {
      $parameters | Add-Property -Name "spot_instance_policy" -Value $SpotInstancePolicy
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Add-DatabricksSQLEndpoint -Value Add-DatabricksSQLWarehouse


Function Remove-DatabricksSQLWarehouse {
  <#
      .SYNOPSIS
      Delete a SQL endpoint.
      .DESCRIPTION
      Delete a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#delete
      .PARAMETER SQLEndpointID 
      ID of the SQL endpoint you want to delete.
      .EXAMPLE
      Remove-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointID
  )
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointID"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Remove-DatabricksSQLEndpoint -Value Remove-DatabricksSQLWarehouse


Function Update-DatabricksSQLWarehouse {
  <#
			.SYNOPSIS
			Modify a SQL endpoint. All fields are optional. Missing fields default to the current values.
			.DESCRIPTION
			Modify a SQL endpoint. All fields are optional. Missing fields default to the current values.
			Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#edit
      .PARAMETER SQLEndpointID 
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
      .PARAMETER EnableServerlessCompute
			Whether to enable Serverles. 
      .PARAMETER Channel
			Whether to use preview-featueres or not. 
      .PARAMETER SpotInstancePolicy
			What type of Spot instances to use - Cost-Optimized or Reliability-Optimized
			.EXAMPLE
			Update-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef" -Name "My updated SQL Endpoint" -ClusterSize "Large" -MinNumclusters 2 -MaxNumclusters 8 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointID,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("endpoint_name")] [string] $Name,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_size")] [ValidateSet("2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large")] [string] $ClusterSize,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("min_num_clusters")] [int] $MinNumClusters = -1,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("max_num_clusters")] [int] $MaxNumClusters = -1,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("auto_stop_mins")] [int] $AutoStopMinutes,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false)] [object] $Tags,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_photon")] [Nullable[bool]] $EnablePhoton,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("enable_serverless_compute")] [Nullable[bool]] $EnableServerlessCompute,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false)] [ValidateSet("CHANNEL_NAME_PREVIEW", "CHANNEL_NAME_CURRENT")] [string] $Channel,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("spot_instance_policy")] [ValidateSet("COST_OPTIMIZED", "RELIABILITY_OPTIMIZED")] [string] $SpotInstancePolicy
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {

    $apiEndpoint += "/$SQLEndpointID/edit"

    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{}

    if ($PSBoundParameters.ContainsKey('Name')) {
      $parameters | Add-Property -Name "Name" -Value $Name
    }
    if ($PSBoundParameters.ContainsKey('ClusterSize')) {
      $parameters | Add-Property -Name "cluster_size" -Value $ClusterSize
    }
    $parameters | Add-Property -Name "min_num_clusters" -Value $MinNumClusters -NullValue -1
    $parameters | Add-Property -Name "max_num_clusters" -Value $MaxNumClusters -NullValue -1
    if ($PSBoundParameters.ContainsKey('AutoStopMinutes')) {
      $parameters | Add-Property -Name "auto_stop_mins" -Value $AutoStopMinutes
    }
    if ($PSBoundParameters.ContainsKey('Tags')) {
      $parameters | Add-Property -Name "tags" -Value @{custom_tags = ConvertTo-KeyValueArray $tags }
    }
    if ($PSBoundParameters.ContainsKey('EnablePhoton')) {
      $parameters | Add-Property -Name "enable_photon" -Value $EnablePhoton
    }
    if ($PSBoundParameters.ContainsKey('EnableServerlessCompute')) {
      $parameters | Add-Property -Name "enable_serverless_compute" -Value $EnableServerlessCompute
    }
    if ($PSBoundParameters.ContainsKey('Channel')) {
      $parameters | Add-Property -Name "channel" -Value @{name = $Channel }
    }
    if ($PSBoundParameters.ContainsKey('SpotInstancePolicy')) {
      $parameters | Add-Property -Name "spot_instance_policy" -Value $SpotInstancePolicy
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return [PSCustomObject]@{id = $SQLEndpointID }
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Update-DatabricksSQLEndpoint -Value Update-DatabricksSQLWarehouse


Function Get-DatabricksSQLWarehouse {
  <#
      .SYNOPSIS
      List all SQL endpoints in the workspace or Retrieve the info for a SQL endpoint.
      .DESCRIPTION
      Delete a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#get and https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#list
      .PARAMETER SQLEndpointID 
      ID of the SQL endpoint you want to delete
      .EXAMPLE
      #AUTOMATED_TEST:List Databricks SQL Warehouses
      Get-DatabricksSQLWarehouse
      .EXAMPLE
      Get-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointID
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if ($PSBoundParameters.ContainsKey('SQLEndpointID')) {
      $apiEndpoint += "/$SQLEndpointID"
    }

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    
    if ($PSBoundParameters.ContainsKey('SQLEndpointID')) {
      return $result
    }
    else {
      return $result.warehouses
    }
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Get-DatabricksSQLEndpoint -Value Get-DatabricksSQLWarehouse


Function Start-DatabricksSQLWarehouse {
  <#
      .SYNOPSIS
      Start a SQL endpoint.
      .DESCRIPTION
      Start a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#start
      .PARAMETER SQLEndpointID 
      ID of the SQL endpoint you want to start.
      .EXAMPLE
      Start-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointID
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointID/start"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Start-DatabricksSQLEndpoint -Value Start-DatabricksSQLWarehouse


Function Stop-DatabricksSQLWarehouse {
  <#
      .SYNOPSIS
      Stop a SQL endpoint.
      .DESCRIPTION
      Stop a SQL endpoint.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#stop
      .PARAMETER SQLEndpointID 
      ID of the SQL endpoint you want to stop.
      .EXAMPLE
      Stop-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "id")] [string] $SQLEndpointID
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/sql/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$SQLEndpointID/stop"

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
New-Alias -Name Stop-DatabricksSQLEndpoint -Value Stop-DatabricksSQLWarehouse


Function Get-DatabricksSQLWarehouseConfig {
  <#
      .SYNOPSIS
      Get the configuration for all SQL endpoints.
      .DESCRIPTION
      Get the configuration for all SQL endpoints.
      Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#get-1
      .PARAMETER SQLEndpointID 
      ID of the SQL endpoint you want to delete
      .EXAMPLE
      #AUTOMATED_TEST:List Databricks SQL Config
      Get-DatabricksSQLWarehouseConfig
  #>
  [CmdletBinding()]
  param ()
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/config/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
#New-Alias -Name Get-DatabricksSQLEndpointConfig -Value Get-DatabricksSQLWarehouseConfig


Function Update-DatabricksSQLWarehouseConfig {
  <#
			.SYNOPSIS
			Edit the configuration for all SQL endpoints. All fields are required. Invoking this method restarts all running SQL endpoints.
			.DESCRIPTION
			Edit the configuration for all SQL endpoints. All fields are required. Invoking this method restarts all running SQL endpoints.
			Official API Documentation: https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints#edit-1
      .PARAMETER SQLEndpointID 
			ID of the SQL endpoint.This field is required.
			.EXAMPLE
			Add-DatabricksSQLWarehouse -SQLEndpointID "0123456789abcdef" -Name "My updated SQL Endpoint" -ClusterSize "Large" -MinNumclusters 2 -MaxNumclusters 8 -EnablePhoton $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("security_policy")] [ValidateSet("DATA_ACCESS_CONTROL", "PASSTHROUGH", "NONE")] [string] $SecurityPolicy,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("data_access_config")] [object] $DataAccessConfig,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("sql_configuration_parameters")] [object] $SQLConfigurationParameters,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("instance_profile_arn")] [object] $InstanceProfileARN,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("enable_serverless_compute")] [boolean] $EnableServerlessCompute,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
  )
	
  begin {
    $requestMethod = "PUT"
    $apiEndpoint = "/2.0/sql/config/warehouses"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if (-not $Force) {
      Write-Error "This cmdlet will restart all running SQL endpoints. If you want to proceed, please use the -Force parameter!"
      return
    }

    #Set parameters
    $parameters = @{
      security_policy = $SecurityPolicy
    }

    $parameters | Add-Property -Name "instance_profile_arn" -Value $InstanceProfileARN
    $parameters | Add-Property -Name "enable_serverless_compute" -Value $EnableServerlessCompute

    if ($DataAccessConfig) {
      $config = $DataAccessConfig
      if ($DataAccessConfig.GetType().Name -eq 'hashtable') {
        $config = ConvertTo-KeyValueArray $DataAccessConfig
      }
      
      $parameters | Add-Property -Name "data_access_config" -Value $config
    }

    if ($SQLConfigurationParameters) {
      $config = $SQLConfigurationParameters
      if ($SQLConfigurationParameters.GetType().Name -eq 'hashtable') {
        $config = @{configuration_pairs = ConvertTo-KeyValueArray $SQLConfigurationParameters }
      }
      $parameters | Add-Property -Name "sql_configuration_parameters" -Value $sqlConfig
    }
    

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
# function was renamed on 2022-10-04 - for backwards compatiblity an alias is added with the old name
#Set-Alias -Name "Update-DatabricksSQLEndpointConfig" -Value "Update-DatabricksSQLWarehouseConfig"
#Export-ModuleMember -Alias "Update-DatabricksSQLEndpointConfig"