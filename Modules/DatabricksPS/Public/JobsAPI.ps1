Function Add-DatabricksJob
{
  <#
      .SYNOPSIS
      Creates a new job with the provided settings.
      .DESCRIPTION
      Creates a new job with the provided settings.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#create
      .PARAMETER Name 
      An optional name for the job. The default value is Untitled.
      .PARAMETER ClusterID 
      The ID of an existing cluster that will be used for the job. When running jobs on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs on new clusters for greater reliability.
      .PARAMETER NewClusterDefinition
	
      .PARAMETER Libraries 
      An optional list of libraries to be installed on the cluster that will execute the job. The default value is an empty list.
      Sample:
      $libraries = @(
      @{"jar" = "dbfs:/jars/sqldb.jar"},
      @{"maven" = @{"coordinates" = "org.jsoup:jsoup:1.7.2"} }
      )
      .PARAMETER TimeoutSeconds 
      An optional timeout applied to each run of this job. The default behavior is to have no timeout.
      .PARAMETER MaxRetries 
      An optional maximum number of times to retry an unsuccessful run. A run is considered to be unsuccessful if it completes with a FAILED result_state or INTERNAL_ERROR life_cycle_state. The value -1 means to retry indefinitely and the value 0 means to never retry. The default behavior is to never retry.
      .PARAMETER MinRetryIntervalMillis 
      An optional minimal interval in milliseconds between attempts. The default behavior is that unsuccessful runs are immediately retried.
      .PARAMETER RetryOnTimeout 
      An optional policy to specify whether to retry a job when it times out. The default behavior is to not retry on timeout.
      .PARAMETER MaxConcurrentRuns 
      An optional maximum allowed number of concurrent runs of the job.
      Set this value if you want to be able to execute multiple runs of the same job concurrently. This is useful for example if you trigger your job on a frequent schedule and want to allow consecutive runs to overlap with each other, or if you want to trigger multiple runs which differ by their input parameters.
      This setting affects only new runs. For example, suppose the job's concurrency is 4 and there are 4 concurrent active runs. Then setting the concurrency to 3 won't kill any of the active runs. However, from then on, new runs are skipped unless there are fewer than 3 active runs.
      This value cannot exceed 1000. Setting this value to 0 causes all new runs to be skipped. The default behavior is to allow only 1 concurrent run.

      .PARAMETER EmailNotifications 
      An optional set of email addresses notified when runs of this job begin and complete and when this job is deleted. The default behavior is to not send any emails.
      Sample: 
      $emailNotifications = @{
      "on_start" = @("me@home.com", "you@home.com")
      "on_success" = @()
      "on_failure" = @("me@home.com")
      }
      .PARAMETER Schedule 
      An optional periodic schedule for this job. The default behavior is that the job runs when triggered by clicking Run Now in the Jobs UI or sending an API request to runNow.
      Sample:
      $schedule = @{
      "quartz_cron_expression" = "0 15 22 ? * *"
      "timezone_id" = "America/Los_Angeles"
      }
      .PARAMETER NotebookPath
      The Path of the notebook to execute.
      .PARAMETER NotebookParameters
      A hashtable containing the parameters to pass to the notebook
      Sample:
      $notebookParams: @{
      "dry-run" = "true",
      "oldest-time-to-consider" = "1457570074236"
      }
      .PARAMETER PythonURI
      The URI of the Python file to be executed. DBFS and S3 paths are supported. This field is required.
      .PARAMETER PythonParameters
      Command line parameters that will be passed to the Python file.
      Sample:
      $pythonParameters = @("john doe","35")

      .PARAMETER JarURI
      Deprecated since 04/2016. Provide a jar through the libraries field instead. For an example, see Create.
      .PARAMETER JarMainClassName
      The full name of the class containing the main method to be executed. This class must be contained in a JAR provided as a library.
      The code should use SparkContext.getOrCreate to obtain a Spark context; otherwise, runs of the job will fail.
      Sample:
      $jarMainClassName = @{"main_class_name" = "com.databricks.ComputeModels"}
      .PARAMETER JarParameters
      Parameters that will be passed to the main method.
      Sample:
      $jarParameters = @("john doe","35")
      .PARAMETER SparkParameters 
      Command line parameters passed to spark submit.
      .OUTPUT
      PSObject with the following properties
      - job_id
      .EXAMPLE
      Add-DatabricksJob -Name "DatabricksPSTest" -ClusterID '1234-123456-abc789' -TimeoutSeconds 60 -NotebookPath '/Users/me@home.com/myNotebook'
  #>
  [CmdletBinding()]
  param
  (
    # generic parameters
    [Parameter(ParameterSetName = "Notebook", Mandatory = $true, Position = 1)]
    [Parameter(ParameterSetName = "Python", Mandatory = $true, Position = 1)]
    [Parameter(ParameterSetName = "Jar", Mandatory = $true, Position = 1)] 
    [Parameter(ParameterSetName = "Spark", Mandatory = $true, Position = 1)] [string] $Name,

    #[Parameter(Mandatory = $false)] [string] $ClusterID,
    [Parameter(Mandatory = $false)] [object] $NewClusterDefinition, 
 
    [Parameter(Mandatory = $false)] [hashtable[]] $Libraries, 
    [Parameter(Mandatory = $false)] [int32] $TimeoutSeconds = -1,
    [Parameter(Mandatory = $false)] [int32] $MaxRetries = -1,
    [Parameter(Mandatory = $false)] [int32] $MinRetryIntervalMilliseconds = -1,
    [Parameter(Mandatory = $false)] [nullable[bool]] $RetryOnTimeout,
    [Parameter(Mandatory = $false)] [int32] $MaxConcurrentRuns = -1,
				
    [Parameter(Mandatory = $false)] [object] $Schedule,
				
    [Parameter(Mandatory = $false)] [object] $EMailNotifications, 
		
    [Parameter(ParameterSetName = "JobDefinition", Mandatory = $true)] [object] $JobSettings,
					
    [Parameter(ParameterSetName = "Notebook", Mandatory = $true, Position = 2)] [string] $NotebookPath, 
    [Parameter(ParameterSetName = "Notebook", Mandatory = $false, Position = 3)] [hashtable] $NotebookParameters, 

		
    [Parameter(ParameterSetName = "Python", Mandatory = $true, Position = 2)] [string] $PythonURI, 
    [Parameter(ParameterSetName = "Python", Mandatory = $false, Position = 3)] [string[]] $PythonParameters,
		
		
    [Parameter(ParameterSetName = "Jar", Mandatory = $true, Position = 2)] [string] $JarURI, 
    [Parameter(ParameterSetName = "Jar", Mandatory = $true, Position = 2)] [string] $JarMainClassName, 
    [Parameter(ParameterSetName = "Jar", Mandatory = $false, Position = 3)] [string[]] $JarParameters, 

    [Parameter(ParameterSetName = "Spark", Mandatory = $true, Position = 2)] [string] $SparkParameters
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id'-DPDictionary $Dictionary

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/create"
    
    $ClusterID = $PSBoundParameters.ClusterID
  }

  process
  {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."	
    $parameters = @{}
	
    $parameters | Add-Property -Name "name" -Value $Name -Force
	
    if($PSCmdlet.ParameterSetName -ne "JobDefinition")
    {		
      if($NewClusterDefinition)
      {
        $parameters | Add-Property -Name "new_cluster" -Value $NewClusterDefinition
      }
      elseif($ClusterID)
      {
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
      }
      else
      {
        Write-Error "Either parameter NewClusterDefinition or parameter ClusterID have to be specified!"
      }
    }
			
    switch ($PSCmdlet.ParameterSetName) 
    { 
      "JobDefinition" {					
        $parameters = $JobSettings | ConvertTo-Hashtable
			
        $parameters.email_notifications.on_success | ConvertTo-Hashtable
      }
		
      "Notebook" {
        $notebookTask = @{ notebook_path = $NotebookPath }
        $notebookTask | Add-Property  -Name "base_parameters" -Value $NotebookParameters

        #Set parameters
			
        $parameters | Add-Property -Name "notebook_task" -Value $notebookTask
      }
		
      "Jar" {
        $jarTask = @{ 
          jar_uri = $JarURI 
          main_class_name = $JarMainClassName
        }
        $jarTask | Add-Property  -Name "parameters" -Value $JarParameters

        #Set parameters
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
        $parameters | Add-Property -Name "spark_jar_task" -Value $jarTask
      }
		
      "Python" {
        $pythonTask = @{ 
          python_file = $PythonURI 
        }
        $pythonTask | Add-Property  -Name "parameters" -Value $PythonParameters

        #Set parameters
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
        $parameters | Add-Property -Name "spark_python_task" -Value $pythonTask
      }
		
      "Spark" {
        $sparkTask = @{ 
          parameters = $SparkParameters 
        }

        #Set parameters
			
        $parameters | Add-Property -Name "spark_submit_task" -Value $sparkTask
      }
    }
	
    $parameters | Add-Property -Name "libraries" -Value $Libraries
    $parameters | Add-Property -Name "timeout_seconds" -Value $TimeoutSeconds -NullValue -1
    $parameters | Add-Property -Name "max_retries" -Value $MaxRetries -NullValue -1
    $parameters | Add-Property -Name "min_retry_interval_millis" -Value $MinRetryIntervalMilliseconds -NullValue -1
    $parameters | Add-Property -Name "retry_on_timeout" -Value $RetryOnTimeout
    $parameters | Add-Property -Name "max_concurrent_runs" -Value $MaxConcurrentRuns -NullValue -1
    $parameters | Add-Property -Name "schedule" -Value $Schedule
    $parameters | Add-Property -Name "email_notifications" -Value $EMailNotifications
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}
Function Get-DatabricksJob
{
  <#
      .SYNOPSIS
      Lists all jobs or returns a specific job for a given JobID.
      .DESCRIPTION
      Lists all jobs or returns a specific job for a given JobID. 
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#list
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#get
      .PARAMETER JobID 
      The canonical identifier of the job retrieve. This field is optional and can be used as a filter on one particular job id.
      .OUTPUT
      List of PSObjects with the following properties
      - job_id
      - settings
      .EXAMPLE
      Get-DatabricksJob -JobID 123
      .EXAMPLE
      #AUTOMATED_TEST:List existing clusters
      Get-DatabricksJob
  #>
  [CmdletBinding()]
  param 
  (	
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("job_id")] [int64] $JobID = -1
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/jobs/list"
    
    if($JobID -gt 0)
    {
      Write-Verbose "JobID specified ($JobID)- using Get-API instead of List-API..."
      $apiEndpoint = "/2.0/jobs/get?job_id=$JobID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if($JobID -gt 0)
    {
      # if a JobID was specified, we return the result as it is
      return $result
    }
    else
    {
      # if no JobID was specified, we return the jobs as an array
      return $result.jobs
    }
  }
}

Function Remove-DatabricksJob
{
  <#
      .SYNOPSIS
      Deletes the job and sends an email to the addresses specified in JobSettings.email_notifications. No action will occur if the job has already been removed. After the job is removed, neither its details or its run history will be visible via the Jobs UI or API. The job is guaranteed to be removed upon completion of this request. However, runs that were active before the receipt of this request may still be active. They will be terminated asynchronously.
      .DESCRIPTION
      Deletes the job and sends an email to the addresses specified in JobSettings.email_notifications. No action will occur if the job has already been removed. After the job is removed, neither its details or its run history will be visible via the Jobs UI or API. The job is guaranteed to be removed upon completion of this request. However, runs that were active before the receipt of this request may still be active. They will be terminated asynchronously.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#delete
      .PARAMETER JobID 
      The canonical identifier of the job to delete. This field is required.
      .OUTPUT
      None
      .EXAMPLE
      Remove-DatabricksJob -JobID <JobID>
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("job_id")] [int64] $JobID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobIDValues = (Get-DynamicParamValues { Get-Databricksjob }).job_id
    New-DynamicParam -Name JobID -ValidateSet $jobIDValues -Alias 'job_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/delete"
    
    $JobID = $PSBoundParameters.JobID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      job_id = $JobID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    # This API call does not return any result
    #return $result
  }
}

Function Update-DatabricksJob
{
  <#
      .SYNOPSIS
      Overwrites the settings of a job with the provided settings.
      .DESCRIPTION
      Overwrites the settings of a job with the provided settings.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#reset
      .PARAMETER JobID 
      The canonical identifier of the job to reset. This field is required.
      .PARAMETER NewSettings 
      The new settings of the job. These new settings replace the old settings entirely.
      Changes to the following fields are not applied to active runs: JobSettings.cluster_spec or JobSettings.task.
      Changes to the following fields are applied to active runs as well as future runs: JobSettings.timeout_second, JobSettings.email_notifications, or JobSettings.retry_policy. This field is required.
      .OUTPUTS
      None
      .EXAMPLE
      Update-DatabricksJob -JobID 1 -NewSettings <new_settings>
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("job_id")] [int64] $JobID, 
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("settings")] [object] $NewSettings
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobIDValues = (Get-DynamicParamValues { Get-Databricksjob }).job_id
    New-DynamicParam -Name JobID -ValidateSet $jobIDValues -Alias 'job_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/reset"
    
    $JobID = $PSBoundParameters.JobID
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      job_id = $JobID 
      new_settings = $NewSettings 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # This API call does not return any result
    # return $result 
  }
}

Function Start-DatabricksJob
{
  <#
      .SYNOPSIS
      Runs an existing job now, and returns the run_id of the triggered run.
      .DESCRIPTION
      Runs an existing job now, and returns the run_id of the triggered run.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#run-now
      .PARAMETER JobID
      The canonical identifier of the job to start. This field is required.
      .PARAMETER JarParams 
      A list of parameters for jobs with jar tasks, e.g. "jar_params": ["john doe", "35"]. The parameters will be used to invoke the main function of the main class specified in the Spark jar task. If not specified upon run-now, it will default to an empty list. jar_params cannot be specified in conjunction with notebook_params. The JSON representation of this field (i.e. {"jar_params":["john doe","35"]}) cannot exceed 10,000 bytes.
      .PARAMETER NotebookParams 
      A map from keys to values for jobs with notebook task, e.g. "notebook_params": {"name": "john doe", "age":  "35"}. The map is passed to the notebook and will be accessible through the dbutils.widgets.get function. See Widgets for more information.
      If not specified upon run-now, the triggered run uses the job's base parameters.
      notebook_params cannot be specified in conjunction with jar_params.
      The JSON representation of this field (i.e. {"notebook_params":{"name":"john doe","age":"35"}}) cannot exceed 10,000 bytes.
      .PARAMETER PythonParams 
      A list of parameters for jobs with Python tasks, e.g. "python_params": ["john doe", "35"]. The parameters will be passed to Python file as command line parameters. If specified upon run-now, it would overwrite the parameters specified in job setting. The JSON representation of this field (i.e. {"python_params":["john doe","35"]}) cannot exceed 10,000 bytes.
      .PARAMETER SparkSubmitParams 
      A list of parameters for jobs with spark submit task, e.g. "spark_submit_params": ["--class", "org.apache.spark.examples.SparkPi"]. The parameters will be passed to spark-submit script as command line parameters. If specified upon run-now, it would overwrite the parameters specified in job setting. The JSON representation of this field cannot exceed 10,000 bytes.
      .OUTPUTS
      PSObject with the following properties:
      - run_id
      - number_in_job
      .EXAMPLE
      Start-DatabricksJob -JobID <JobID> -NotebookParams @{ param1 = 123; param2 = "MyTextParam" }
  #>
  [CmdletBinding(DefaultParametersetname = "Jar")]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("job_id")] [int64] $JobID, 
    [Parameter(ParameterSetName = "Jar", Mandatory = $false, Position = 2)] [string[]] $JarParams = @(), 
    [Parameter(ParameterSetName = "Notebook", Mandatory = $false, Position = 3)] [hashtable] $NotebookParams = @{}, 
    [Parameter(ParameterSetName = "Python", Mandatory = $false, Position = 4)] [string[]] $PythonParams = @(), 
    [Parameter(ParameterSetName = "Spark", Mandatory = $false, Position = 5)] [string[]] $SparkSubmitParams = @()
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobIDValues = (Get-DynamicParamValues { Get-Databricksjob }).job_id
    New-DynamicParam -Name JobID -ValidateSet $jobIDValues -Alias 'job_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/run-now"
    
    $JobID = $PSBoundParameters.JobID
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      job_id = $JobID 
    }
	
    $parameters | Add-Property  -Name "jar_params" -Value $JarParams -NullValue @()
    $parameters | Add-Property  -Name "notebook_params" -Value $NotebookParams -NullValue @{}
    $parameters | Add-Property  -Name "python_params" -Value $PythonParams -NullValue @()
    $parameters | Add-Property  -Name "spark_submit_params" -Value $SparkSubmitParams -NullValue @()

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function New-DatabricksJobRun
{
  <#
      .SYNOPSIS
      Submit a one-time run with the provided settings. This endpoint doesn't require a Databricks job to be created. You can directly submit your workload. Runs submitted via this endpoint don't show up in the UI. Once the run is submitted, you can use the jobs/runs/get API to check the run state.
      .DESCRIPTION
      Submit a one-time run with the provided settings. This endpoint doesn't require a Databricks job to be created. You can directly submit your workload. Runs submitted via this endpoint don't show up in the UI. Once the run is submitted, you can use the jobs/runs/get API to check the run state.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-submit
      .PARAMETER ClusterID 
      The ID of an existing cluster that will be used for all runs of this job. When running jobs on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs on new clusters for greater reliability.
      .PARAMETER NewClusterDefinition
      A description of a cluster that will be created for each run.

      .PARAMETER NotebookPath
      The Path of the notebook to execute.
      .PARAMETER NotebookParameters
      A hashtable containing the parameters to pass to the notebook
			
      .PARAMETER PythonURI
      The URI of the Python file to be executed. DBFS and S3 paths are supported. This field is required.
      .PARAMETER PythonParameters
      Command line parameters that will be passed to the Python file.

      .PARAMETER JarURI
      Deprecated since 04/2016. Provide a jar through the libraries field instead. For an example, see Create.
      .PARAMETER JarMainClassName
      The full name of the class containing the main method to be executed. This class must be contained in a JAR provided as a library.
      The code should use SparkContext.getOrCreate to obtain a Spark context; otherwise, runs of the job will fail.
      .PARAMETER JarParameters
      Parameters that will be passed to the main method.

      .PARAMETER SparkParameters 
      Command line parameters passed to spark submit.
			
      .PARAMETER Name 
      An optional name for the run. The default value is Untitled.
      .PARAMETER Libraries 
      An optional list of libraries to be installed on the cluster that will execute the job. The default value is an empty list.
      .PARAMETER TimeoutSeconds 
      An optional timeout applied to each run of this job. The default behavior is to have no timeout.
      .OUTPUTS
      PSObject with the following properties:
      - run_id
      - number_in_job
      .EXAMPLE
      New-DatabricksJobRun -ClusterID "1234-asdfae-1234" -NotebookPath "/Shared/MyNotebook" -RunName "MyJobRun" -TimeoutSeconds 300
  #>
	
  [CmdletBinding(DefaultParametersetname="JarJob")]
  param
  (
    #[Parameter(ParameterSetName = "NotebookJob", Mandatory = $true)]
    #[Parameter(ParameterSetName = "PythonkJob", Mandatory = $true)]
    #[Parameter(ParameterSetName = "JarJob", Mandatory = $true)]
    #[Parameter(ParameterSetName = "SparkJob", Mandatory = $true)] [int64] $JobID,
		
    [Parameter(ParameterSetName = "Notebook", Mandatory = $true, Position = 2)] [string] $NotebookPath, 
    [Parameter(ParameterSetName = "Notebook", Mandatory = $false, Position = 3)]
    [Parameter(ParameterSetName = "NotebookJob", Mandatory = $false, Position = 3)] [hashtable] $NotebookParameters, 

		
    [Parameter(ParameterSetName = "Python", Mandatory = $true, Position = 2)] [string] $PythonURI, 
    [Parameter(ParameterSetName = "Python", Mandatory = $false, Position = 3)]
    [Parameter(ParameterSetName = "PythonJob", Mandatory = $false, Position = 3)] [string[]] $PythonParameters,
		
		
    [Parameter(ParameterSetName = "Jar", Mandatory = $true, Position = 2)] [string] $JarURI, 
    [Parameter(ParameterSetName = "Jar", Mandatory = $true, Position = 2)] [string] $JarMainClassName, 
    [Parameter(ParameterSetName = "Jar", Mandatory = $false, Position = 3)] 
    [Parameter(ParameterSetName = "JarJob", Mandatory = $false, Position = 3)] [string[]] $JarParameters, 

		
    [Parameter(ParameterSetName = "Spark", Mandatory = $true, Position = 1)] [object] $NewClusterDefinition, 
    [Parameter(ParameterSetName = "Spark", Mandatory = $true, Position = 2)]
    [Parameter(ParameterSetName = "SparkJob", Mandatory = $false, Position = 2)] [string] $SparkParameters, 
		
    # generic parameters
    #[Parameter(Mandatory = $false, Position = 1)] [string] $ClusterID, 
    [Parameter(Mandatory = $false, Position = 4)] [string] $RunName, 
    [Parameter(Mandatory = $false, Position = 5)] [string[]] $Libraries, 
    [Parameter(Mandatory = $false, Position = 6)] [int32] $TimeoutSeconds = -1
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobIDValues = (Get-DynamicParamValues { Get-Databricksjob }).job_id
    New-DynamicParam -Name JobID -ParameterSetName NotebookJob,PythonkJob,JarJob,SparkJob -ValidateSet $jobIDValues -Alias 'job_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary

    $clusterIDValues = (Get-DynamicParamValues { Get-DatabricksCluster }).cluster_id
    New-DynamicParam -Name ClusterID -ValidateSet $clusterIDValues -Alias 'cluster_id'-DPDictionary $Dictionary

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/runs/submit"
    
    $ClusterID = $PSBoundParameters.ClusterID
    $JobID = $PSBoundParameters.JobID
    
    if($PSCmdlet.ParameterSetName.EndsWith("Job"))
    {
      $apiEndpoint = "/2.0/jobs/run-now"
    }
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{}
    switch ($PSCmdlet.ParameterSetName) 
    { 
      "Notebook" {
        $notebookTask =  @{ notebook_path = $NotebookPath }
        $notebookTask | Add-Property  -Name "base_parameters" -Value $NotebookParameters

        #Set parameters
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
        $parameters | Add-Property -Name "notebook_task" -Value $notebookTask
      }
		
      "Jar" {
        $jarTask =  @{ 
          jar_uri = $JarURI 
          main_class_name = $JarMainClassName
        }
        $jarTask | Add-Property  -Name "parameters" -Value $JarParameters

        #Set parameters
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
        $parameters | Add-Property -Name "spark_jar_task" -Value $jarTask
      }
		
      "Python" {
        $pythonTask =  @{ 
          python_file = $PythonURI 
        }
        $pythonTask | Add-Property  -Name "parameters" -Value $PythonParameters

        #Set parameters
        $parameters | Add-Property -Name "existing_cluster_id" -Value $ClusterID
        $parameters | Add-Property -Name "spark_python_task" -Value $pythonTask
      }
		
      "Spark" {
        $sparkTask =  @{ 
          parameters = $SparkParameters 
        }

        #Set parameters
        $parameters | Add-Property -Name "new_cluster" -Value $NewClusterDefinition
        $parameters | Add-Property -Name "spark_submit_task" -Value $sparkTask
      }
		
      "NotebookJob" {
        $parameters | Add-Property -Name "job_id" -Value $JobID

        #Set parameters
        $parameters | Add-Property -Name "notebook_params" -Value $NotebookParameters
      }
		
      "PythonJob" {
        $parameters | Add-Property -Name "job_id" -Value $JobID

        #Set parameters
        $parameters | Add-Property -Name "python_params" -Value $PythonParameters
      }
		
      "JarJob" {
        $parameters | Add-Property -Name "job_id" -Value $JobID

        #Set parameters
        $parameters | Add-Property -Name "jar_params" -Value $JarParameters
      }
		
      "SparkJob" {
        $parameters | Add-Property -Name "job_id" -Value $JobID

        #Set parameters
        $parameters | Add-Property -Name "spark_submit_params" -Value $SparkParameters
      }
    }
	
    $parameters | Add-Property -Name "run_name" -Value $RunName
    $parameters | Add-Property -Name "libraries" -Value $Libraries
    $parameters | Add-Property -Name "timeout_seconds" -Value $TimeoutSeconds -NullValue -1

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Get-DatabricksJobRun
{
  <#
      .SYNOPSIS
      Lists runs from most recently started to least.
      .DESCRIPTION
      Lists runs from most recently started to least.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-list
      .PARAMETER JobRunID 
      The canonical identifier of the run for which to retrieve the metadata. This field is required.
      .PARAMETER JobID 
      The job for which to list runs. If omitted, the Jobs service will list runs from all jobs.
      .PARAMETER List 
      Optional parameter to list the all JobRuns, which is also the default. 
      .PARAMETER Filter
      If ActiveOnly, if true, only active runs will be included in the results; otherwise, lists both active and completed runs.
      Note: This field cannot be true when CompletedOnly is true.
      If CompletedOnly, if true, only completed runs will be included in the results; otherwise, lists both active and completed runs.
      Note: This field cannot be true when ActiveOnly is true.
      .PARAMETER Offset 
      The offset of the first run to return, relative to the most recent run.
      .PARAMETER Limit 
      The number of runs to return. This value should be greater than 0 and less than 1000. The default value is 20. If a request specifies a limit of 0, the service will instead use the maximum limit.
      .OUTPUTS
      PSObject with the following properties:
      - job_id
      - run_id
      - number_in_job
      - original_attempt_run_id
      - state 
      - schedule
      - task
      - cluster_spec
      - cluster_instance
      - start_time
      - setup_duration
      - execution_duration
      - cleanup_duration
      - trigger
      - creator_user_name
      - run_name
      - run_page_url
      - run_type
      .EXAMPLE
      Get-DatabricksJobRun -Filter ActiveOnly -JobID <JobID> -Offset <offset> -Limit <limit>
  #>
  [CmdletBinding(DefaultParametersetName = "ByJobId")]
  param
  (
    [Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("job_id")] [int64] $JobID = -1, 
    [Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 2)] [string] [ValidateSet("ActiveOnly", "CompletedOnly", "All")] $Filter = "All",
    [Parameter(ParameterSetName = "ByJobId", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [int32] $Offset = -1, 
    [Parameter(ParameterSetName = "ByJobId", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [int32] $Limit = -1,
		
    [Parameter(ParameterSetName = "ByRunId", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName=$true)] [Alias("run_id")] [int64] $JobRunID
  )

  begin {
    $requestMethod = "GET"
    switch ($PSCmdlet.ParameterSetName) 
    { 
      "ByJobId"  { 
                    $apiEndpoint = "/2.0/jobs/runs/list" 
                 } 
      "ByRunId"  { 
                    $apiEndpoint = "/2.0/jobs/runs/get" } 
                 } 
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{}
    switch ($PSCmdlet.ParameterSetName) 
    { 
      "ByJobId" {
        $parameters | Add-Property -Name "job_id" -Value $JobID -NullValue -1
        $parameters | Add-Property -Name "offset" -Value $Offset -NullValue -1 
        $parameters | Add-Property -Name "limit" -Value $Limit -NullValue -1
			
        if($Filter -eq "ActiveOnly") { $parameters | Add-Property -Name "active_only" -Value $true }
        if($Filter -eq "CompletedOnly") { $parameters | Add-Property -Name "completed_only" -Value $true }
      }

      "ByRunId" {
        $parameters | Add-Property -Name "run_id" -Value $JobRunID -NullValue -1
      }
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    switch ($PSCmdlet.ParameterSetName) 
    { 
      "ByJobId"  { return $result.runs } 
      "ByRunId"  { return $result } 
    } 
  }
}


Function Export-DatabricksJobRun
{
  <#
      .SYNOPSIS
      Exports and retrieves the job run task.
      .DESCRIPTION
      Exports and retrieves the job run task.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-export
      .PARAMETER JobRunId 
      The canonical identifier for the run. This field is required.
      .PARAMETER Views_To_Export 
      Which views to export (CODE, DASHBOARDS, or ALL). Defaults to CODE.
      .OUTPUTS
      List of PSObject with the following properties:
      - content
      - name
      - type
      .EXAMPLE
      Export-DatabricksJobRun -JobRunID 1 -ViewsToExport All
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("run_id")] [int64] $JobRunId, 
    [Parameter(Mandatory = $false, Position = 2)] [string] [ValidateSet("Code", "Dashboards", "All")] $ViewsToExport = "All"
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobRunIDValues = (Get-DynamicParamValues { Get-DatabricksJobRun }).run_id
    New-DynamicParam -Name JobRunId -ValidateSet $jobRunIDValues -Alias 'run_id' -Type Int64 -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/jobs/runs/export"
    
    $JobRunId = $PSBoundParameters.JobRunId
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      run_id = $JobRunID 
      views_to_export = $ViewsToExport 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.views
  }
}


Function Stop-DatabricksJobRun
{
  <#
      .SYNOPSIS
      Cancels a run. The run is canceled asynchronously, so when this request completes the run may be still be active. The run will be terminated as soon as possible.
      .DESCRIPTION
      Cancels a run. The run is canceled asynchronously, so when this request completes, the run may still be running. The run will be terminated shortly. If the run is already in a terminal life_cycle_state, this method is a no-op.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-cancel
      .PARAMETER JobRunID 
      The canonical identifier for the run to cancel. This field is required.
      .OUTPUTS
      None
      .EXAMPLE
      Stop-DatabricksJobRun -JobRunID 1
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("run_id")] [int64] $JobRunID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobRunIDValues = (Get-DynamicParamValues { Get-DatabricksJobRun }).run_id
    New-DynamicParam -Name JobRunId -ValidateSet $jobRunIDValues -Alias 'run_id' -Type Int64 -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/runs/cancel"
    
    $JobRunId = $PSBoundParameters.JobRunId
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      run_id = $JobRunID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # This API call does not return any result
    # return $result 
  }
}


Function Get-DatabricksJobRunOutput
{
  <#
      .SYNOPSIS
      Retrieves both the output and the metadata of a run.
      .DESCRIPTION
      Retrieve the output of a run. When a notebook task returns value through the dbutils.notebook.exit() call, you can use this endpoint to retrieve that value. Databricks restricts this API to return the first 5 MB of the output. For returning a larger result, you can store job results in a cloud storage service.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-get-output
      .PARAMETER JobRunID 
      The canonical identifier for the run. This field is required.
      .OUTPUTS
      PSObject with the following properties:
      - metadata
      - notebook_output OR error
      .EXAMPLE
      Get-DatabricksJobRunOutput -JobRunID 1
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("run_id")] [int64] $JobRunID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobRunIDValues = (Get-DynamicParamValues { Get-DatabricksJobRun }).run_id
    New-DynamicParam -Name JobRunId -ValidateSet $jobRunIDValues -Alias 'run_id' -Type Int64 -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/jobs/runs/get-output"
    
    $JobRunId = $PSBoundParameters.JobRunId
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      run_id = $JobRunID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Remove-DatabricksJobRun
{
  <#
      .SYNOPSIS
      Deletes a non-active run. Returns an error if the run is active.
      .DESCRIPTION
      Deletes a non-active run. Returns an error if the run is active.
      Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-delete
      .PARAMETER JobRunID 
      The canonical identifier of the run for which to retrieve the metadata.
      .OUTPUTS
      None
      .EXAMPLE
      Remove-DatabricksJobRun -JobRunID 1
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("run_id")] [int64] $JobRunID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $jobRunIDValues = (Get-DynamicParamValues { Get-DatabricksJobRun }).run_id
    New-DynamicParam -Name JobRunId -ValidateSet $jobRunIDValues -Alias 'run_id' -Type Int64 -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/jobs/runs/delete"
    
    $JobRunId = $PSBoundParameters.JobRunId
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      run_id = $JobRunID 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # This API call does not return any result
    # return $result 
  }
}