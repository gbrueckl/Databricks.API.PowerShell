Function Add-DatabricksInstancePool
{
  <#
      .SYNOPSIS
      Create an instance pool. Use the returned instance_pool_id to query the status of the instance pool, which includes the number of instances currently allocated by the pool. If you provide the min_idle_instances parameter, instances are provisioned in the background and are ready to use once the idle_count in the InstancePoolStats equals the requested minimum.
      .DESCRIPTION
      Create an instance pool. Use the returned instance_pool_id to query the status of the instance pool, which includes the number of instances currently allocated by the pool. If you provide the min_idle_instances parameter, instances are provisioned in the background and are ready to use once the idle_count in the InstancePoolStats equals the requested minimum.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/instance-pools.html#create
      .PARAMETER InstancePoolName 
      The name of the instance pool. This is required for create and edit operations. It must be unique, non-empty, and less than 100 characters.
      .PARAMETER MinIdleInstances 
      The minimum number of idle instances maintained by the pool. This is in addition to any instances in use by active clusters.
      .PARAMETER MaxCapacity 
      The maximum number of instances the pool can contain, including both idle instances and ones in use by clusters. Once the maximum capacity is reached, you cannot create new clusters from the pool and existing clusters cannot autoscale up until some instances are made idle in the pool via cluster termination or down-scaling.
      .PARAMETER NodeTypeId 
      The node type for the instances in the pool. All clusters attached to the pool inherit this node type and the poolâs idle instances are allocated based on this type. You can retrieve a list of available node types by using the List Node Types API call.
      .PARAMETER CustomTags 
      Additional tags for instance pool resources. Databricks tags all pool resources (e.g. AWS instances and EBS volumes) with these tags in addition to default_tags.

      Databricks allows at most 43 custom tags.
      .PARAMETER IdleInstanceAutoterminationMinutes 
      The number of minutes that idle instances in excess of the min_idle_instances are maintained by the pool before being terminated. If not specified, excess idle instances are terminated automatically after a default timeout period. If specified, the time must be between 0 and 10000 minutes. If you specify 0, excess idle instances are removed as soon as possible.
      .PARAMETER EnableElasticDisk 
      Autoscaling Local Storage: when enabled, the instances in the pool dynamically acquire additional disk space when they are running low on disk space.
      .PARAMETER DiskSpec 
      Defines the amount of initial remote storage attached to each instance in the pool.
      .PARAMETER PreloadedSparkVersions 
      A list with the runtime version the pool installs on each instance. Pool clusters that use a preloaded runtime version start faster as they do have to wait for the image to download. You can retrieve a list of available runtime versions by using the Runtime Versions API call.
      .EXAMPLE
      Add-DatabricksInstancePool -Instance_Pool_Name <instance_pool_name> -Min_Idle_Instances <min_idle_instances> -Max_Capacity <max_capacity> -Aws_Attributes <aws_attributes> -Node_Type_Id <node_type_id> -Custom_Tags <custom_tags> -Idle_Instance_Autotermination_Minutes <idle_instance_autotermination_minutes> -Enable_Elastic_Disk <enable_elastic_disk> -Disk_Spec <disk_spec> -Preloaded_Spark_Versions <preloaded_spark_versions>
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1)] [string] $InstancePoolName, 
    [Parameter(Mandatory = $true, Position = 2)] [int32] $MinIdleInstances, 
    [Parameter(Mandatory = $true, Position = 3)] [int32] $MaxCapacity, 
    #[Parameter(Mandatory = $false, Position = 4)] [hashtable] $AwsAttributes, 
    #[Parameter(Mandatory = $false, Position = 5)] [string] $NodeTypeId, 
    [Parameter(Mandatory = $false, Position = 6)] [hashtable] $CustomTags,
    [Parameter(Mandatory = $false, Position = 7)] [int32] $IdleInstanceAutoterminationMinutes, 
    [Parameter(Mandatory = $false, Position = 8)] [bool] $EnableElasticDisk, 
    [Parameter(Mandatory = $false, Position = 9)] [hashtable] $DiskSpec
    #[Parameter(Mandatory = $false, Position = 10)] [array] $PreloadedSparkVersions
  )
  
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $nodeTypeIdValues = (Get-DynamicParamValues { Get-DatabricksNodeType }).node_type_id
    New-DynamicParam -Name NodeTypeId -ValidateSet $nodeTypeIdValues -Mandatory -DPDictionary $Dictionary

    $sparkVersionValues = (Get-DynamicParamValues { Get-DatabricksSparkVersion }).key
    New-DynamicParam -Name PreloadedSparkVersions -ValidateSet $sparkVersionValues -Type string[] -DPDictionary $Dictionary

    if($script:dbCloudProvider -in  @("AWS"))
    {
      $awsZoneValues = (Get-DynamicParamValues { Get-DatabricksZone }).key
      New-DynamicParam -Name AwsZone -ValidateSet $awsZoneValues -Type string[] -DPDictionary $Dictionary
           
      New-DynamicParam -Name AwsAvailability -ValidateSet @('SPOT', 'ON_DEMAND', 'SPOT_WITH_FALLBACK') -Type string -DPDictionary $Dictionary
      New-DynamicParam -Name AwsAttributes -Type hashtable -DPDictionary $Dictionary
    }
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }

  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/instance-pools/create"

    $NodeTypeId = $PSBoundParameters.NodeTypeId
    $PreloadedSparkVersions = $PSBoundParameters.PreloadedSparkVersions
    $AwsZone = $PSBoundParameters.AwsZone
    $AwsAvailability = $PSBoundParameters.AwsAvailability
  }

  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    if($InstancePoolName)
    {
      $parameters = $InstancePoolName | ConvertTo-Hashtable
    }
    else
    {
      $parameters = @{}
    }
    
    if(-not $AwsAttributes) # check if a ClusterMode was explicitly specified
    {
      if($script:dbCloudProvider -in  @("AWS"))
      {
        $AwsAttributes = @{}
        
        $AwsAttributes | Add-Property -Name "availability" -Value $AwsAvailability -Force
        $AwsAttributes | Add-Property -Name "zone_id" -Value $AwsZone -Force
      }
      Write-Verbose "AwsAttributes set to $AwsAttributes"
    }
    
    $parameters | Add-Property -Name "instance_pool_name" -Value $InstancePoolName -Force
    $parameters | Add-Property -Name "min_idle_instances" -Value $MinIdleInstances -Force
    $parameters | Add-Property -Name "max_capacity" -Value $MaxCapacity -Force
    $parameters | Add-Property -Name "aws_attributes" -Value $AwsAttributes -Force
    $parameters | Add-Property -Name "node_type_id" -Value $NodeTypeId -Force
    $parameters | Add-Property -Name "custom_tags" -Value $CustomTags -Force
    $parameters | Add-Property -Name "idle_instance_autotermination_minutes" -Value $IdleInstanceAutoterminationMinutes -Force
    $parameters | Add-Property -Name "enable_elastic_disk" -Value $EnableElasticDisk -Force
    $parameters | Add-Property -Name "disk_spec" -Value $DiskSpec -Force
    $parameters | Add-Property -Name "preloaded_spark_versions" -Value $PreloadedSparkVersions -Force
			
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
	
    return $result
  }
}

Function Update-DatabricksInstancePool
{
  <#
      .SYNOPSIS
      Edit an instance pool. This modifies the configuration of an existing instance pool.
      .DESCRIPTION
      Edit an instance pool. This modifies the configuration of an existing instance pool.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/instance-pools.html#edit
      .PARAMETER InstancePoolId 
      The ID of the instance pool to edit. This field is required.
      .PARAMETER InstancePoolName 
      The name of the instance pool. This is required for create and edit operations. It must be unique, non-empty, and less than 100 characters.
      .PARAMETER MinIdleInstances 
      The minimum number of idle instances maintained by the pool. This is in addition to any instances in use by active clusters.
      .PARAMETER MaxCapacity 
      The maximum number of instances the pool can contain, including both idle instances and ones in use by clusters. Once the maximum capacity is reached, you cannot create new clusters from the pool and existing clusters cannot autoscale up until some instances are made idle in the pool via cluster termination or down-scaling.
      .PARAMETER NodeTypeId 
      The node type for the instances in the pool. All clusters attached to the pool inherit this node type and the poolâs idle instances are allocated based on this type. You can retrieve a list of available node types by using the List Node Types API call.
      .PARAMETER IdleInstanceAutoterminationMinutes 
      The number of minutes that idle instances in excess of the min_idle_instances are maintained by the pool before being terminated. If not specified, excess idle instances are terminated automatically after a default timeout period. If specified, the time must be between 0 and 10000 minutes. If 0 is supplied, excess idle instances are removed as soon as possible.
      .EXAMPLE
      Update-DatabricksInstancePool -Instance_Pool_Id <instance_pool_id> -Instance_Pool_Name <instance_pool_name> -Min_Idle_Instances <min_idle_instances> -Max_Capacity <max_capacity> -Node_Type_Id <node_type_id> -Idle_Instance_Autotermination_Minutes <idle_instance_autotermination_minutes>
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1)] [Alias("instance_pool_id")] [string] $InstancePoolId, 
    [Parameter(Mandatory = $true, Position = 2)] [string] $InstancePoolName, 
    [Parameter(Mandatory = $false, Position = 3)] [int32] $MinIdleInstances, 
    [Parameter(Mandatory = $false, Position = 4)] [int32] $MaxCapacity, 
    #[Parameter(Mandatory = $false, Position = 5)] [string] $NodeTypeId, 
    [Parameter(Mandatory = $false, Position = 6)] [int32] $IdleInstanceAutoterminationMinutes
  )
      
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $nodeTypeIdValues = (Get-DynamicParamValues { Get-DatabricksNodeType }).node_type_id
    New-DynamicParam -Name NodeTypeId -ValidateSet $nodeTypeIdValues -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
    
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/instance-pools/edit"

    $NodeTypeId = $PSBoundParameters.NodeTypeId
  }
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    if($InstancePoolName)
    {
      $parameters = $InstancePoolName | ConvertTo-Hashtable
    }
    else
    {
      $parameters = @{}
    }
   
    $parameters | Add-Property -Name "instance_pool_name" -Value $InstancePoolName -Force
    $parameters | Add-Property -Name "min_idle_instances" -Value $MinIdleInstances -Force
    $parameters | Add-Property -Name "max_capacity" -Value $MaxCapacity -Force
    $parameters | Add-Property -Name "node_type_id" -Value $NodeTypeId -Force
    $parameters | Add-Property -Name "idle_instance_autotermination_minutes" -Value $IdleInstanceAutoterminationMinutes -Force
			
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
	
    return $result
  }
}

Function Delete-DatabricksInstancePool
{
  <#
      .SYNOPSIS
      Delete an instance pool. This permanently deletes the instance pool. The idle instances in the pool are terminated asynchronously. New clusters cannot attach to the pool. Running clusters attached to the pool continue to run but cannot autoscale up. Terminated clusters attached to the pool will fail to start until they are edited to no longer use the pool.
      .DESCRIPTION
      Delete an instance pool. This permanently deletes the instance pool. The idle instances in the pool are terminated asynchronously. New clusters cannot attach to the pool. Running clusters attached to the pool continue to run but cannot autoscale up. Terminated clusters attached to the pool will fail to start until they are edited to no longer use the pool.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/instance-pools.html#delete
      .PARAMETER InstancePoolID 
      The ID of the instance pool to delete.
      .EXAMPLE
      Delete-DatabricksInstancePool -InstancePoolID <instance_pool_id>
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1)] [Alias("instance_pool_id")] [string] $InstancePoolID
  )
  
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $instancePoolValues = (Get-DynamicParamValues { Get-DatabricksInstancePools }).instance_pool_id
    New-DynamicParam -Name InstancePoolID -ValidateSet $instancePoolValues -Alias 'instance_pool_id' -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
      
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/instance-pools/delete"

    $InstancePoolID = $PSBoundParameters.InstancePoolID
  }
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}

    $parameters | Add-Property -Name "instance_pool_id" -Value $InstancePoolID -Force
			
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
	
    return $result
  }
}

Function Get-DatabricksInstancePool
{
  <#
      .SYNOPSIS
      Retrieve the information for an instance pool given its identifier.
      .DESCRIPTION
      Retrieve the information for an instance pool given its identifier.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/instance-pools.html#get
      .PARAMETER InstancePoolID 
      The instance pool about which to retrieve information.
      .PARAMETER List 
      Optional parameter to list the all InstancePools, which is also the default. 
      .EXAMPLE
      Get-DatabricksInstancePool -InstancePoolID <instance_pool_id>
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false)] [switch] $List
    #[Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("instance_pool_id")] [string] $InstancePoolID
  )
  
  DynamicParam
  {
    if(-not $List)
    {
      #Create the RuntimeDefinedParameterDictionary
      $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
      $instancePoolValues = (Get-DynamicParamValues { Get-DatabricksInstancePools -List }).instance_pool_id
      New-DynamicParam -Name InstancePoolID -ValidateSet $instancePoolValues -Alias 'instance_pool_id' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
      #return RuntimeDefinedParameterDictionary
      return $Dictionary
    }
  }

  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/instance-pools/list"
    
    $InstancePoolID = $PSBoundParameters.InstancePoolID
    
    if($InstancePoolID)
    {
      Write-Verbose "InstancePoolId specified ($InstancePoolID) - using get endpoint instead of list endpoint..."
      $apiEndpoint =  "/2.0/instance-pools/get"
    }
  }

  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}
    $parameters | Add-Property  -Name "instance_pool_id" -Value $InstancePoolID

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if($InstancePoolID)
    {
      # if a InstancePool was specified, we return the result as it is
      return $result
    }
    else
    {
      # if no InstancePool was specified, we return the InstancePools as an array
      return $result.instance_pools
    }
  }
}