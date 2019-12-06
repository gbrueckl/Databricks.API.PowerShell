Function Add-DatabricksCluster
{
  <#
      .SYNOPSIS
      Creates a new Spark cluster. This method acquires new instances from the cloud provider if necessary. This method is asynchronous; the returned cluster_id can be used to poll the cluster state. When this method returns, the cluster is in a PENDING state. The cluster is usable once it enters a RUNNING state. See ClusterState.
      You can either specify all single properties of the cluster on your own or provide a cluster object that contains all the properties.
      Single properties will overwrite the values in the cluster object!
      .DESCRIPTION
      Creates a new Spark cluster. This method acquires new instances from the cloud provider if necessary. This method is asynchronous; the returned cluster_id can be used to poll the cluster state. When this method returns, the cluster is in a PENDING state. The cluster is usable once it enters a RUNNING state. See ClusterState.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#create
      .PARAMETER ClusterObject
      A PowerShell object representing the definition of a cluster according to Databricks documentation.
      .PARAMETER NumWorkers
      Number of worker nodes that this cluster should have. A cluster has one Spark Driver and num_workers Executors for a total of num_workers + 1 Spark nodes.
      Note: When reading the properties of a cluster, this field reflects the desired number of workers rather than the actual current number of workers. For instance, if a cluster is resized from 5 to 10 workers, this field will immediately be updated to reflect the target size of 10 workers, whereas the workers listed in spark_info will gradually increase from 5 to 10 as the new nodes are provisioned.
      .PARAMETER MinWorkers 
      The minimum number of workers to provision for this autoscale-enabled cluster.
      .PARAMETER MaxWorkers 
      The maximum number of workers to provision for this autoscale-enabled cluster.
      .PARAMETER ClusterName 
      Cluster name requested by the user. This doesn't have to be unique. If not specified at creation, the cluster name will be an empty string.
      .PARAMETER SparkVersion 
      The Spark version of the cluster. A list of available Spark versions can be retrieved by using the List SparkVersions API call. This field is required.
      .PARAMETER SparkConf 
      An object containing a set of optional, user-specified Spark configuration key-value pairs. You can also pass in a string of extra JVM options to the driver and the executors via spark.driver.extraJavaOptions and spark.executor.extraJavaOptions respectively. Example Spark confs: {"spark.speculation": true, "spark.streaming.ui.retainedBatches": 5} or {"spark.driver.extraJavaOptions": "-verbose:gc -XX:+PrintGCDetails"}
      .PARAMETER AwsAttributes 
      Attributes related to clusters running on Amazon Web Services. If not specified at cluster creation, a set of default values will be used.
      .PARAMETER NodeTypeId 
      This field encodes, through a single value, the resources available to each of the Spark nodes in this cluster. For example, the Spark nodes can be provisioned and optimized for memory or compute intensive workloads A list of available node types can be retrieved by using the List Node Types API call. This field is required.
      .PARAMETER DriverNodeTypeId 
      The node type of the Spark driver. Note that this field is optional; if unset, the driver node type will be set as the same value as node_type_id defined above.
      .PARAMETER SshPublicKeys 
      SSH public key contents that will be added to each Spark node in this cluster. The corresponding private keys can be used to login with the user name ubuntu on port 2200. Up to 10 keys can be specified.
      .PARAMETER CustomTags 
      Additional tags for cluster resources. Databricks will tag all cluster resources (e.g., AWS instances and EBS volumes) with these tags in addition to default_tags. Notes:
      Tags are not supported on legacy node types such as compute-optimized and memory-optimized 
      Databricks allows at most 45 custom tags 
      .PARAMETER ClusterLogConf 
      The configuration for delivering Spark logs to a long-term storage destination. Only one destination can be specified for one cluster. If the conf is given, the logs will be delivered to the destination every 5 mins. The destination of driver logs is <destination>/<cluster-id>/driver, while the destination of executor logs is <destination>/<cluster-id>/executor.
      .PARAMETER InitScripts 
      The configuration for storing init scripts. Any number of destinations can be specified. The scripts are executed sequentially in the order provided. If cluster_log_conf is specified, init script logs are sent to <destination>/<cluster-id>/init_scripts.
      $init_scripts = @( @{ "dbfs" = @{ "destination" = "dbfs:/databricks/my-init-script.sh"; }; } )
      .PARAMETER SparkEnvVars 
      An object containing a set of optional, user-specified environment variable key-value pairs. Key-value pairs of the form (X,Y) are exported as is (i.e., export X='Y') while launching the driver and workers. In order to specify an additional set of SPARK_DAEMON_JAVA_OPTS, we recommend appending them to $SPARK_DAEMON_JAVA_OPTS as shown in the example below. This ensures that all default databricks managed environmental variables are included as well. Example Spark environment variables: {"SPARK_WORKER_MEMORY": "28000m", "SPARK_LOCAL_DIRS": "/local_disk0"} or {"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS -Dspark.shuffle.service.enabled=true"}
      .PARAMETER AutoterminationMinutes 
      Automatically terminates the cluster after it is inactive for this time in minutes. If not set, this cluster will not be automatically terminated. If specified, the threshold must be between 10 and 10000 minutes. You can also set this value to 0 to explicitly disable automatic termination.
      .PARAMETER EnableElasticDisk 
      Autoscaling Local Storage: when enabled, this cluster will dynamically acquire additional disk space when its Spark workers are running low on disk space. This feature requires specific AWS permissions to function correctly - refer to Autoscaling local storage for details.
      .PARAMETER PythonVersion 
      Allows you to explicitly set the Python version for the cluster by adding the entry 'PYSPARK_PYTHON' to the SparkEnvVars parameter. Default is Python 2 (2.7) 
      For details please refer to https://docs.azuredatabricks.net/user-guide/clusters/python3.html
      .EXAMPLE
      Add-DatabricksCluster -NumWorkers 2 -ClusterName "MyCluster" -SparkVersion "4.0.x-scala2.11" -NodeTypeId 'Standard_DS3_v2'
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ParameterSetName = "FixedSize", Mandatory = $true, Position = 1)] [int32] $NumWorkers,
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 1)] [int32] $MinWorkers, 
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 2)] [int32] $MaxWorkers, 
		
    [Parameter(ParameterSetName = "ClusterObject", Mandatory = $false, Position = 3)] [object] $ClusterObject,
		
    [Parameter(Mandatory = $false, Position = 3)] [string] $ClusterName, 
    #[Parameter(Mandatory = $false, Position = 3)] [string] $SparkVersion, 
    [Parameter(Mandatory = $false, Position = 4)] [hashtable] $SparkConf, 
    [Parameter(Mandatory = $false, Position = 5)] [hashtable] $AwsAttributes, 
    #[Parameter(Mandatory = $false, Position = 6)] [string] $NodeTypeId, 
    #[Parameter(Mandatory = $false, Position = 7)] [string] $DriverNodeTypeId, 
    [Parameter(Mandatory = $false, Position = 8)] [string[]] $SshPublicKeys, 
    [Parameter(Mandatory = $false, Position = 9)] [hashtable] $CustomTags, 
    [Parameter(Mandatory = $false, Position = 10)] [object] $ClusterLogConf, 
    [Parameter(Mandatory = $false, Position = 11)] [object[]] $InitScripts, 
    [Parameter(Mandatory = $false, Position = 12)] [hashtable] $SparkEnvVars, 
    [Parameter(Mandatory = $false, Position = 13)] [int32] $AutoterminationMinutes, 
    [Parameter(Mandatory = $false, Position = 14)] [bool] $EnableElasticDisk,
    [Parameter(Mandatory = $false, Position = 15)] [string] [ValidateSet("2 (2.7)", "3 (3.5)")] $PythonVersion = "3 (3.5)",
    [Parameter(Mandatory = $false, Position = 16)] [string] [ValidateSet("HighConcurrency", "Standard")] $ClusterMode
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $nodeTypeIdValues = (Get-DynamicParamValues { Get-DatabricksNodeType }).node_type_id
    New-DynamicParam -Name NodeTypeId -ValidateSet $nodeTypeIdValues -DPDictionary $Dictionary
    New-DynamicParam -Name DriverNodeTypeId -ValidateSet $nodeTypeIdValues -DPDictionary $Dictionary

    $sparkVersionValues = (Get-DynamicParamValues { Get-DatabricksSparkVersion }).key
    New-DynamicParam -Name SparkVersion -ValidateSet $sparkVersionValues -DPDictionary $Dictionary

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
    
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/create"

    $NodeTypeId = $PSBoundParameters.NodeTypeId
    $DriverNodeTypeId = $PSBoundParameters.DriverNodeTypeId
    $SparkVersion = $PSBoundParameters.SparkVersion
  }

  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    if($ClusterObject)
    {
      $parameters = $ClusterObject | ConvertTo-Hashtable
    }
    else
    {
      $parameters = @{}
    }
	
    if($PythonVersion) # check if a PythonVersion was explicitly specified
    {
      if(-not $SparkEnvVars) # ensure that the SparkEnvVars variable exists - otherwise create it as empty hashtable
      {
        $SparkEnvVars = @{}
      }
      switch($PythonVersion) # set PYSPARK_PYTHON environment variable accordingly
      { 
        '2 (2.7)'  { $SparkEnvVars | Add-Property -Name 'PYSPARK_PYTHON' -Value '/databricks/python/bin/python' -Force } 
        '3 (3.5)'  { $SparkEnvVars | Add-Property -Name 'PYSPARK_PYTHON' -Value '/databricks/python3/bin/python3' -Force }
      }
      Write-Verbose "PythonVersion set to $PythonVersion"
    }
	
    if($ClusterMode) # check if a ClusterMode was explicitly specified
    {
      if(-not $CustomTags) # ensure that the SparkConf variable exists - otherwise create it as empty hashtable
      {
        $CustomTags = @{}
      }
      switch($ClusterMode) # set PYSPARK_PYTHON environment variable accordingly
      { 
        'Standard'  { $CustomTags | Add-Property -Name "ResourceClass" -Value "Standard" -Force } 
        'HighConcurrency'  { $CustomTags | Add-Property -Name "ResourceClass" -Value "Serverless" -Force }
      }
      Write-Verbose "ClusterMode set to $ClusterMode"
    }

    $parameters | Add-Property -Name "cluster_name" -Value $ClusterName -Force
    $parameters | Add-Property -Name "spark_version" -Value $SparkVersion -Force
    $parameters | Add-Property -Name "node_type_id" -Value $NodeTypeId -Force
    $parameters | Add-Property -Name "spark_conf" -Value $SparkConf -Force
    $parameters | Add-Property -Name "aws_attributes" -Value $AwsAttributes -Force
    $parameters | Add-Property -Name "driver_node_type_id" -Value $DriverNodeTypeId -Force
    $parameters | Add-Property -Name "ssh_public_keys" -Value $SshPublicKeys -Force
    $parameters | Add-Property -Name "custom_tags" -Value $CustomTags -Force
    $parameters | Add-Property -Name "cluster_log_conf" -Value $ClusterLogConf -Force
    $parameters | Add-Property -Name "init_scripts" -Value $InitScripts -Force
    $parameters | Add-Property -Name "spark_env_vars" -Value $SparkEnvVars -Force
    $parameters | Add-Property -Name "autotermination_minutes" -Value $AutoterminationMinutes -NullValue 0 -Force
    $parameters | Add-Property -Name "enable_elastic_disk" -Value $EnableElasticDisk -Force
	
    switch($PSCmdlet.ParameterSetName) 
    { 
      "FixedSize"  { $parameters | Add-Property -Name "num_workers" -Value $NumWorkers -Force } 
      "Autoscale"  { $parameters | Add-Property -Name "autoscale" -Value @{ min_workers = $MinWorkers; max_workers = $MaxWorkers } -Force }
    } 

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
	
    return $result
  }
}

Function Update-DatabricksCluster
{
  <#
      .SYNOPSIS
      Edit the configuration of a cluster to match the provided attributes and size.
      You can edit a cluster if it is in a RUNNING or TERMINATED state. If you edit a cluster while it is in a RUNNING state, it will be restarted so that the new attributes can take effect. If you edit a cluster while it is in a TERMINATED state, it will remain TERMINATED. The next time it is started using the clusters/start API, the new attributes will take effect. An attempt to edit a cluster in any other state will be rejected with an INVALID_STATE error code.
      Clusters created by the Databricks Jobs service cannot be edited.
      You can either specify all single properties of the cluster on your own or provide a cluster object that contains all the properties.
      Single properties will overwrite the values in the cluster object!
      .DESCRIPTION
      Edit the configuration of a cluster to match the provided attributes and size.
      You can edit a cluster if it is in a RUNNING or TERMINATED state. If you edit a cluster while it is in a RUNNING state, it will be restarted so that the new attributes can take effect. If you edit a cluster while it is in a TERMINATED state, it will remain TERMINATED. The next time it is started using the clusters/start API, the new attributes will take effect. An attempt to edit a cluster in any other state will be rejected with an INVALID_STATE error code.
      Clusters created by the Databricks Jobs service cannot be edited.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#edit
			
      .PARAMETER ClusterID 
      The ID of the cluster to be edited. 
      .PARAMETER ClusterObject
      A PowerShell object representing the definition of a cluster according to Databricks documentation.
      .PARAMETER NumWorkers
      Number of worker nodes that this cluster should have. A cluster has one Spark Driver and num_workers Executors for a total of num_workers + 1 Spark nodes.
      Note: When reading the properties of a cluster, this field reflects the desired number of workers rather than the actual current number of workers. For instance, if a cluster is resized from 5 to 10 workers, this field will immediately be updated to reflect the target size of 10 workers, whereas the workers listed in spark_info will gradually increase from 5 to 10 as the new nodes are provisioned.
      .PARAMETER MinWorkers 
      The minimum number of workers to provision for this autoscale-enabled cluster.
      .PARAMETER MaxWorkers 
      The maximum number of workers to provision for this autoscale-enabled cluster.
      .PARAMETER ClusterName 
      Cluster name requested by the user. This doesn't have to be unique. If not specified at creation, the cluster name will be an empty string.
      .PARAMETER SparkVersion 
      The Spark version of the cluster. A list of available Spark versions can be retrieved by using the List SparkVersions API call. This field is required.
      .PARAMETER SparkConf 
      An object containing a set of optional, user-specified Spark configuration key-value pairs. You can also pass in a string of extra JVM options to the driver and the executors via spark.driver.extraJavaOptions and spark.executor.extraJavaOptions respectively. Example Spark confs: {"spark.speculation": true, "spark.streaming.ui.retainedBatches": 5} or {"spark.driver.extraJavaOptions": "-verbose:gc -XX:+PrintGCDetails"}
      .PARAMETER AwsAttributes 
      Attributes related to clusters running on Amazon Web Services. If not specified at cluster creation, a set of default values will be used.
      .PARAMETER NodeTypeId 
      This field encodes, through a single value, the resources available to each of the Spark nodes in this cluster. For example, the Spark nodes can be provisioned and optimized for memory or compute intensive workloads A list of available node types can be retrieved by using the List Node Types API call. This field is required.
      .PARAMETER Drive_NodeTypeId 
      The node type of the Spark driver. Note that this field is optional; if unset, the driver node type will be set as the same value as node_type_id defined above.
      .PARAMETER SshPublicKeys 
      SSH public key contents that will be added to each Spark node in this cluster. The corresponding private keys can be used to login with the user name ubuntu on port 2200. Up to 10 keys can be specified.
      .PARAMETER CustomTags 
      Additional tags for cluster resources. Databricks will tag all cluster resources (e.g., AWS instances and EBS volumes) with these tags in addition to default_tags. Notes:
      Tags are not supported on legacy node types such as compute-optimized and memory-optimized 
      Databricks allows at most 45 custom tags 
      .PARAMETER ClusterLogConf 
      The configuration for delivering Spark logs to a long-term storage destination. Only one destination can be specified for one cluster. If the conf is given, the logs will be delivered to the destination every 5 mins. The destination of driver logs is <destination>/<cluster-id>/driver, while the destination of executor logs is <destination>/<cluster-id>/executor.
      .PARAMETER InitScripts 
      The configuration for storing init scripts. Any number of destinations can be specified. The scripts are executed sequentially in the order provided. If cluster_log_conf is specified, init script logs are sent to <destination>/<cluster-id>/init_scripts.
      $init_scripts = @( @{ "dbfs" = @{ "destination" = "dbfs:/databricks/my-init-script.sh"; }; } )
      .PARAMETER SparkEnvVars 
      An object containing a set of optional, user-specified environment variable key-value pairs. Key-value pairs of the form (X,Y) are exported as is (i.e., export X='Y') while launching the driver and workers. In order to specify an additional set of SPARK_DAEMON_JAVA_OPTS, we recommend appending them to $SPARK_DAEMON_JAVA_OPTS as shown in the example below. This ensures that all default databricks managed environmental variables are included as well. Example Spark environment variables: {"SPARK_WORKER_MEMORY": "28000m", "SPARK_LOCAL_DIRS": "/local_disk0"} or {"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS -Dspark.shuffle.service.enabled=true"}
      .PARAMETER AutoterminationMinutes 
      Automatically terminates the cluster after it is inactive for this time in minutes. If not set, this cluster will not be automatically terminated. If specified, the threshold must be between 10 and 10000 minutes. You can also set this value to 0 to explicitly disable automatic termination.
      .PARAMETER EnableElasticDisk 
      Autoscaling Local Storage: when enabled, this cluster will dynamically acquire additional disk space when its Spark workers are running low on disk space. This feature requires specific AWS permissions to function correctly - refer to Autoscaling local storage for details.
      .EXAMPLE
      Update-DatabricksCluster -NumWorkers 2 -ClusterName "MyCluster" -SparkVersion "4.0.x-scala2.11" -NodeTypeId "i3.xlarge"
  #>
  [CmdletBinding(DefaultParametersetName = "FixedSize")]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 

    [Parameter(ParameterSetName = "FixedSize", Mandatory = $false, Position = 2)] [int32] $NumWorkers,
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $false, Position = 2)] [int32] $MinWorkers, 
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $false, Position = 3)] [int32] $MaxWorkers, 
		
    [Parameter(Mandatory = $false, Position = 3)] [object] $ClusterObject,
    [Parameter(Mandatory = $false, Position = 3)] [string] $ClusterName, 
    #[Parameter(Mandatory = $false, Position = 3)] [string] $SparkVersion, 
    [Parameter(Mandatory = $false, Position = 4)] [hashtable] $SparkConf, 
    [Parameter(Mandatory = $false, Position = 5)] [hashtable] $AwsAttributes, 
    #[Parameter(Mandatory = $false, Position = 6)] [string] $NodeTypeId, 
    #[Parameter(Mandatory = $false, Position = 7)] [string] $DriverNodeTypeId, 
    [Parameter(Mandatory = $false, Position = 8)] [string[]] $SshPublicKeys, 
    [Parameter(Mandatory = $false, Position = 9)] [hashtable] $CustomTags, 
    [Parameter(Mandatory = $false, Position = 10)] [object] $ClusterLogConf, 
    [Parameter(Mandatory = $false, Position = 11)] [object[]] $InitScripts, 
    [Parameter(Mandatory = $false, Position = 12)] [hashtable] $SparkEnvVars, 
    [Parameter(Mandatory = $false, Position = 13)] [int32] $AutoterminationMinutes, 
    [Parameter(Mandatory = $false, Position = 14)] [bool] $EnableElasticDisk,
    [Parameter(Mandatory = $false, Position = 15)] [string] [ValidateSet("2 (2.7)", "3 (3.5)")] $PythonVersion
  )
	
    DynamicParam
    {
        #Create the RuntimeDefinedParameterDictionary
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
        $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
        New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
    
        $nodeTypeIdValues = (Get-DynamicParamValues { Get-DatabricksNodeType }).node_type_id
        New-DynamicParam -Name NodeTypeId -ValidateSet $nodeTypeIdValues -DPDictionary $Dictionary
        New-DynamicParam -Name DriverNodeTypeId -ValidateSet $nodeTypeIdValues -DPDictionary $Dictionary

        $sparkVersionValues = (Get-DynamicParamValues { Get-DatabricksSparkVersion }).key
        New-DynamicParam -Name SparkVersion -ValidateSet $sparkVersionValues -DPDictionary $Dictionary

        #return RuntimeDefinedParameterDictionary
        return $Dictionary
    }

    begin {
      $requestMethod = "POST"
      $apiEndpoint = "/2.0/clusters/edit"

      $ClusterID = $PSBoundParameters.ClusterID
      $NodeTypeId = $PSBoundParameters.NodeTypeId
      $DriverNodeTypeId = $PSBoundParameters.DriverNodeTypeId
      $SparkVersion = $PSBoundParameters.SparkVersion
    }

    process {
      #Set parameters
      Write-Verbose "Building Body/Parameters for final API call ..."
      if($ClusterObject)
      {
        $parameters = $ClusterObject | ConvertTo-Hashtable
      }
      else
      {
        $parameters = @{}
      }
	
      if($PythonVersion) # check if a PythonVersion was explicitly specified
      {
        if(-not $SparkEnvVars) # ensure that the SparkEnvVars variable exists - otherwise create it as empty hashtable
        {
          $SparkEnvVars = @{}
        }
        switch($PythonVersion) # set PYSPARK_PYTHON environment variable accordingly
        { 
          '2 (2.7)'  { $SparkEnvVars | Add-Property -Name 'PYSPARK_PYTHON' -Value '/databricks/python/bin/python' -Force } 
          '3 (3.5)'  { $SparkEnvVars | Add-Property -Name 'PYSPARK_PYTHON' -Value '/databricks/python3/bin/python3' -Force }
        }
        Write-Verbose "PythonVersion set to $PythonVersion"
      }

      $parameters | Add-Property -Name "cluster_id" -Value $ClusterID -Force
      $parameters | Add-Property -Name "cluster_name" -Value $ClusterName -Force
      $parameters | Add-Property -Name "spark_version" -Value $SparkVersion -Force
      $parameters | Add-Property -Name "node_type_id" -Value $NodeTypeId -Force
      $parameters | Add-Property -Name "spark_conf" -Value $SparkConf -Force
      $parameters | Add-Property -Name "aws_attributes" -Value $AwsAttributes -Force
      $parameters | Add-Property -Name "driver_node_type_id" -Value $DriverNodeTypeId -Force
      $parameters | Add-Property -Name "ssh_public_keys" -Value $SshPublicKeys -Force
      $parameters | Add-Property -Name "custom_tags" -Value $CustomTags -Force
      $parameters | Add-Property -Name "cluster_log_conf" -Value $ClusterLogConf -Force
      $parameters | Add-Property -Name "init_scripts" -Value $InitScripts -Force
      $parameters | Add-Property -Name "spark_env_vars" -Value $SparkEnvVars -Force
      $parameters | Add-Property -Name "autotermination_minutes" -Value $AutoterminationMinutes -NullValue 0 -Force
      $parameters | Add-Property -Name "enable_elastic_disk" -Value $EnableElasticDisk -Force
	
      switch($PSCmdlet.ParameterSetName) 
      { 
        "FixedSize"  { $parameters | Add-Property -Name "num_workers" -Value $NumWorkers -Force } 
        "Autoscale"  { $parameters | Add-Property -Name "autoscale" -Value @{ min_workers = $MinWorkers; max_workers = $MaxWorkers } -Force }
      }
	
      $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

      return (ConvertTo-PSObject -InputObject $parameters)
    }
}

Function Start-DatabricksCluster
{
  <#
      .SYNOPSIS
      Starts a terminated Spark cluster given its ID. This is similar to createCluster, except:
      .DESCRIPTION
      Starts a terminated Spark cluster given its ID. This is similar to createCluster, except:
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#start
      .PARAMETER ClusterID 
      The cluster to be started. This field is required.
      .EXAMPLE
      Start-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/start"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }

  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Restart-DatabricksCluster
{
  <#
      .SYNOPSIS
      Restarts a Spark cluster given its id. If the cluster is not in a RUNNING state, nothing will happen.
      .DESCRIPTION
      Restarts a Spark cluster given its id. If the cluster is not in a RUNNING state, nothing will happen.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#restart
      .PARAMETER ClusterID 
      The cluster to be started. This field is required.
      .EXAMPLE
      Restart-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/restart"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Stop-DatabricksCluster
{
  <#
      .SYNOPSIS
      Terminates a Spark cluster given its id. The cluster is removed asynchronously. Once the termination has completed, the cluster will be in a TERMINATED state. If the cluster is already in a TERMINATING or TERMINATED state, nothing will happen.
      .DESCRIPTION
      Terminates a Spark cluster given its id. The cluster is removed asynchronously. Once the termination has completed, the cluster will be in a TERMINATED state. If the cluster is already in a TERMINATING or TERMINATED state, nothing will happen.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#delete-terminate
      .PARAMETER ClusterID 
      The cluster to be terminated. This field is required.
      .EXAMPLE
      Stop-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -ParameterSetName DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/delete"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Resize-DatabricksCluster
{
  <#
      .SYNOPSIS
      Resize a cluster to have a desired number of workers. This will fail unless the cluster is in a RUNNING state.
      .DESCRIPTION
      Resize a cluster to have a desired number of workers. This will fail unless the cluster is in a RUNNING state.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#resize
      .PARAMETER ClusterID 
      The cluster to be resized. This field is required.
      .PARAMETER NumWorkers
      Number of worker nodes that this cluster should have. A cluster has one Spark Driver and num_workers Executors for a total of num_workers + 1 Spark nodes.
      Note: When reading the properties of a cluster, this field reflects the desired number of workers rather than the actual current number of workers. For instance, if a cluster is resized from 5 to 10 workers, this field will immediately be updated to reflect the target size of 10 workers, whereas the workers listed in spark_info will gradually increase from 5 to 10 as the new nodes are provisioned.
      .PARAMETER MinWorkers 
      The minimum number of workers to provision for this autoscale-enabled cluster.
      .PARAMETER MaxWorkers 
      The maximum number of workers to provision for this autoscale-enabled cluster.
      .EXAMPLE
      Resize-DatabricksCluster -ClusterID "1202-211320-brick1" -NumWorkers 10
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID,
    [Parameter(ParameterSetName = "NumberOfWorkers", Mandatory = $true, Position = 2)] [int32] $NumWorkers,
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 2)] [int32] $MinWorkers, 
    [Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 3)] [int32] $MaxWorkers
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/resize"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }
		
    switch($PSCmdlet.ParameterSetName) 
    { 
      "NumberOfWorkers"  { $parameters | Add-Property -Name "num_workers" -Value $NumWorkers -Force } 
      "Autoscale"  { $parameters | Add-Property -Name "autoscale" -Value @{ min_workers = $MinWorkers; max_workers = $MaxWorkers } -Force }
    } 

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Remove-DatabricksCluster
{
  <#
      .SYNOPSIS
      Permanently deletes a Spark cluster. If the cluster is running, it is terminated and its resources are asynchronously removed. If the cluster is terminated, then it is immediately removed.
      .DESCRIPTION
      Permanently deletes a Spark cluster. If the cluster is running, it is terminated and its resources are asynchronously removed. If the cluster is terminated, then it is immediately removed.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#permanent-delete
      .PARAMETER ClusterID 
      The cluster to be permanently deleted. This field is required.
      .EXAMPLE
      Remove-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/permanent-delete"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}

Function Get-DatabricksCluster
{
  <#
      .SYNOPSIS
      Retrieves the information for a cluster given its identifier. Clusters can be described while they are running, or up to 30 days after they are terminated.
      .DESCRIPTION
      Retrieves the information for a cluster given its identifier. Clusters can be described while they are running, or up to 30 days after they are terminated.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#get
      .PARAMETER ClusterID 
      The cluster about which to retrieve information. If left empty, a list of all clusters is returned.
      .EXAMPLE
      Get-DatabricksCluster -ClusterID "1202-211320-brick1"
      .EXAMPLE
      #AUTOMATED_TEST:List existing clusters
      Get-DatabricksCluster
  #>
  param
  (
    [Parameter(Mandatory = $false)] [switch] $IncludeJobClusters,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )

  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/clusters/list"
    
    if($ClusterID)
    {
      Write-Verbose "ClusterID specified ($ClusterID) - using get endpoint instead of list endpoint..."
      $apiEndpoint =  "/2.0/clusters/get"
    }
  }

  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
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
      # if no ClusterID was specified, we return the clusters as an array
      $clusters =  $result.clusters
      
      if(-not $IncludeJobClusters)
      {
        $clusters = $clusters | Where-Object { $_.cluster_source -ne "JOB" }
      }
      
      return $clusters
    }
  }
}

Function Pin-DatabricksCluster			
{
  <#
      .SYNOPSIS
      Note
      .DESCRIPTION
      Note
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#pin
      .PARAMETER ClusterID 
      The cluster to pin. This field is required.
      .EXAMPLE
      Pin-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/pin"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Unpin-DatabricksCluster
{
  <#
      .SYNOPSIS
      Note
      .DESCRIPTION
      Note
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#unpin
      .PARAMETER ClusterID 
      The cluster to unpin. This field is required.
      .EXAMPLE
      Unpin-DatabricksCluster -ClusterID "1202-211320-brick1"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/unpin"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Get-DatabricksClusterEvent
{
  <#
      .SYNOPSIS
      Retrieves a list of events about the activity of a cluster. This API is paginated. If there are more events to read, the response includes all the parameters necessary to request the next page of events.
      .DESCRIPTION
      Retrieves a list of events about the activity of a cluster. This API is paginated. If there are more events to read, the response includes all the parameters necessary to request the next page of events.
      Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#events
      .PARAMETER Cluster_Id 
      The ID of the cluster to retrieve events about. This field is required.
      .PARAMETER Start_Time 
      The start time in epoch milliseconds. If empty, returns events starting from the beginning of time.
      .PARAMETER End_Time 
      The end time in epoch milliseconds. If empty, returns events up to the current time.
      .PARAMETER Order 
      The order to list events in; either ASC or DESC. Defaults to DESC.
      .PARAMETER Event_Types 
      An optional set of event types to filter on. If empty, all event types are returned.
      .PARAMETER Offset 
      The offset in the result set. Defaults to 0 (no offset). When an offset is specified and the results are requested in descending order, the end_time field is required.
      .PARAMETER Limit 
      The maximum number of events to include in a page of events. Defaults to 50, and maximum allowed value is 500.
      .EXAMPLE
      Get-ClusterEvent -ClusterID <cluster_id> -StartTime <start_time> -EndTime <end_time> -Order <order> -EventTypes <event_types> -Offset <offset> -Limit <limit>
      .EXAMPLE
      #AUTOMATED_TEST:Get cluster Events
      $cluster = Get-DatabricksCluster
      $cluster[0] | Get-DatabricksClusterEvent
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $false, Position = 2)] [int64] $StartTime, 
    [Parameter(Mandatory = $false, Position = 3)] [int64] $EndTime, 
    [Parameter(Mandatory = $false, Position = 4)] [ValidateSet("ASC", "DESC")] [string] $Order, 
    [Parameter(Mandatory = $false, Position = 5)] [ValidateSet("CREATING",	"DID_NOT_EXPAND_DISK",	"EXPANDED_DISK",	"FAILED_TO_EXPAND_DISK",	"INIT_SCRIPTS_STARTING",	"INIT_SCRIPTS_FINISHED",	"STARTING",	"RESTARTING",	"TERMINATING",	"EDITED",	"RUNNING",	"RESIZING",	"UPSIZE_COMPLETED",	"NODES_LOST")] [string[]]  $EventTypes, 
    [Parameter(Mandatory = $false, Position = 6)] [int] $Offset = -1, 
    [Parameter(Mandatory = $false, Position = 7)] [int] $Limit = -1
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/clusters/events"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      cluster_id = $ClusterID 
    }
	
    $parameters | Add-Property  -Name "start_time" -Value $StartTime
    $parameters | Add-Property  -Name "end_time" -Value $EndTime
    $parameters | Add-Property  -Name "order" -Value $Order
    $parameters | Add-Property  -Name "event_types" -Value $EventTypes
    $parameters | Add-Property  -Name "offset" -Value $Offset -NullValue -1
    $parameters | Add-Property  -Name "limit" -Value $Limit -NullValue -1

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Get-DatabricksNodeType
{
	<#
			.SYNOPSIS
			Returns a list of supported Spark node types. These node types can be used to launch a cluster.
			.DESCRIPTION
			Returns a list of supported Spark node types. These node types can be used to launch a cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#list-node-types
			.EXAMPLE
			#AUTOMATED_TEST:List cluster node types
			Get-DatabricksNodeType
	#>
	[CmdletBinding()]
	param ()

	$requestMethod = "GET"
	$apiEndpoint = "/2.0/clusters/list-node-types"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{}

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result.node_types
}

Function Get-DatabricksZone
{
	<#
			.SYNOPSIS
			Returns a list of availability zones where clusters can be created in (ex: us-west-2a). These zones can be used to launch a cluster.
			.DESCRIPTION
			Returns a list of availability zones where clusters can be created in (ex: us-west-2a). These zones can be used to launch a cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#list-zones
			.EXAMPLE
			#AUTOMATED_TEST:List cluster zones
			Get-DatabricksZone
			
	#>
	[CmdletBinding()]
	param() 
	
	$requestMethod = "GET"
	$apiEndpoint = "/2.0/clusters/list-zones"
	
	if($script:dbCloudProvider -in  @("Azure"))
	{
		Write-Warning "API call '$requestMethod $apiEndpoint' is not supported on Cloud Provider '$script:dbCloudProvider'"
		return
	}

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{}

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result
}

Function Get-DatabricksSparkVersion
{
	<#
			.SYNOPSIS
			Returns the list of available Spark versions. These versions can be used to launch a cluster.
			.DESCRIPTION
			Returns the list of available Spark versions. These versions can be used to launch a cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#spark-versions
			.EXAMPLE
			#AUTOMATED_TEST:List spark versions
			Get-DatabricksSparkVersion
	#>
	[CmdletBinding()]
	param ()

	$requestMethod = "GET"
	$apiEndpoint = "/2.0/clusters/spark-versions"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{}

	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result.versions
}
