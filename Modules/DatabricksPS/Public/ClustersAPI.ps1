
Function Add-DbCluster
{
	<#
			.SYNOPSIS
			Creates a new Spark cluster. This method acquires new instances from the cloud provider if necessary. This method is asynchronous; the returned cluster_id can be used to poll the cluster state. When this method returns, the cluster is in a PENDING state. The cluster is usable once it enters a RUNNING state. See ClusterState.
			.DESCRIPTION
			Creates a new Spark cluster. This method acquires new instances from the cloud provider if necessary. This method is asynchronous; the returned cluster_id can be used to poll the cluster state. When this method returns, the cluster is in a PENDING state. The cluster is usable once it enters a RUNNING state. See ClusterState.
			Official API Documentation: https://docs.databricks.com/api/latest/clusters.html#create
			.PARAMETER NumWorkers OR Autoscale 
			Number of worker nodes that this cluster should have. A cluster has one Spark Driver and num_workers Executors for a total of num_workers + 1 Spark nodes.
			Note: When reading the properties of a cluster, this field reflects the desired number of workers rather than the actual current number of workers. For instance, if a cluster is resized from 5 to 10 workers, this field will immediately be updated to reflect the target size of 10 workers, whereas the workers listed in spark_info will gradually increase from 5 to 10 as the new nodes are provisioned.
			.PARAMETER MinWorkers 
			The minimum number of workers to provision for this autoscale-enabled cluster.
			.PARAMETER MaxWorkers 
			The maximum number of workers to provision for this autoscale-enabled cluster.
			.PARAMETER ClusterName 
			Cluster name requested by the user. This doesn't have to be unique. If not specified at creation, the cluster name will be an empty string.
			.PARAMETER SparkVersion 
			The Spark version of the cluster. A list of available Spark versions can be retrieved by using the List Zones API call. This field is required.
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
			.PARAMETER SparkEnvVars 
			An object containing a set of optional, user-specified environment variable key-value pairs. Key-value pairs of the form (X,Y) are exported as is (i.e., export X='Y') while launching the driver and workers. In order to specify an additional set of SPARK_DAEMON_JAVA_OPTS, we recommend appending them to $SPARK_DAEMON_JAVA_OPTS as shown in the example below. This ensures that all default databricks managed environmental variables are included as well. Example Spark environment variables: {"SPARK_WORKER_MEMORY": "28000m", "SPARK_LOCAL_DIRS": "/local_disk0"} or {"SPARK_DAEMON_JAVA_OPTS": "$SPARK_DAEMON_JAVA_OPTS -Dspark.shuffle.service.enabled=true"}
			.PARAMETER AutoterminationMinutes 
			Automatically terminates the cluster after it is inactive for this time in minutes. If not set, this cluster will not be automatically terminated. If specified, the threshold must be between 10 and 10000 minutes. You can also set this value to 0 to explicitly disable automatic termination.
			.PARAMETER EnableElasticDisk 
			Autoscaling Local Storage: when enabled, this cluster will dynamically acquire additional disk space when its Spark workers are running low on disk space. This feature requires specific AWS permissions to function correctly - refer to Autoscaling local storage for details.
			.EXAMPLE
			Add-DbCluster -NumWorkers 2 -ClusterName "MyCluster" -SparkVersion "4.0.x-scala2.11" -Node_Type_Id "i3.xlarge"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "FixedSize", Mandatory = $true, Position = 1)] [int32] $NumWorkers,
		[Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 2)] [int32] $MinWorkers, 
		[Parameter(ParameterSetName = "Autoscale", Mandatory = $true, Position = 3)] [int32] $MaxWorkers, 
		
		[Parameter(Mandatory = $true, Position = 3)] [string] $ClusterName, 
		[Parameter(Mandatory = $true, Position = 3)] [string] $SparkVersion, 
		[Parameter(Mandatory = $false, Position = 4)] [hashtable] $SparkConf, 
		[Parameter(Mandatory = $false, Position = 5)] [hashtable] $AwsAttributes, 
		[Parameter(Mandatory = $true, Position = 6)] [string] $NodeTypeId, 
		[Parameter(Mandatory = $false, Position = 7)] [string] $DriverNodeTypeId, 
		[Parameter(Mandatory = $false, Position = 8)] [string[]] $SshPublicKeys, 
		[Parameter(Mandatory = $false, Position = 9)] [string[]] $CustomTags, 
		[Parameter(Mandatory = $false, Position = 10)] [object] $ClusterLogConf, 
		[Parameter(Mandatory = $false, Position = 11)] [string[]] $InitScripts, 
		[Parameter(Mandatory = $false, Position = 12)] [hashtable] $SparkEnvVars, 
		[Parameter(Mandatory = $true, Position = 13)] [int32] $AutoterminationMinutes, 
		[Parameter(Mandatory = $false, Position = 14)] [bool] $EnableElasticDisk
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/clusters/create"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		cluster_name = $ClusterName 
		spark_version = $SparkVersion 
		node_type_id = $NodeTypeId 
		
		
		driver_node_type_id = $DriverNodeTypeId 
		ssh_public_keys = $SshPublicKeys 
		custom_tags = $CustomTags 
		cluster_log_conf = $ClusterLogConf 
		init_scripts = $InitScripts 
		spark_env_vars = $SparkEnvVars 
		autotermination_minutes = $AutoterminationMinutes 
		enable_elastic_disk = $EnableElasticDisk 
	}

	$parameters | Add-Property -Name "spark_conf" -Value $SparkConf
	$parameters | Add-Property -Name "aws_attributes" -Value $AwsAttributes
	$parameters | Add-Property -Name "driver_node_type_id" -Value $DriverNodeTypeId
	$parameters | Add-Property -Name "ssh_public_keys" -Value $SshPublicKeys
	$parameters | Add-Property -Name "custom_tags" -Value $CustomTags
	$parameters | Add-Property -Name "cluster_log_conf" -Value $ClusterLogConf
	$parameters | Add-Property -Name "init_scripts" -Value $InitScripts
	$parameters | Add-Property -Name "spark_env_vars" -Value $SparkEnvVars
	$parameters | Add-Property -Name "autotermination_minutes" -Value $AutoterminationMinutes
	$parameters | Add-Property -Name "enable_elastic_disk" -Value $EnableElasticDisk
	
	switch($PSCmdlet.ParameterSetName) 
	{ 
		"FixedSize"  { $parameters | Add-Property -Name "num_workers" -Value $NumWorkers  } 
		"Autoscale"  { $parameters | Add-Property -Name "autoscale" -Value @{ min_workers = $MinWorkers; max_workers = $MaxWorkers  } }
	} 
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}