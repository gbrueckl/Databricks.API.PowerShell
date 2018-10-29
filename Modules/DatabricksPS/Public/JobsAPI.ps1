Function Get-DbJob
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Lists all jobs. 
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#list
			.PARAMETER JobID 
			The canonical identifier of the job retrieve. This field is optional and can be used as a filter on one particular job id.
			.EXAMPLE
			Get-DbJob -JobID <JobID>
	#>
	[CmdletBinding()]
	param 
	(	
		[Parameter(Mandatory = $false, Position = 1)] [int64] $JobID = -1
	)

	Test-Initialized	 

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/list"
	if($JobID -ne -1)
	{
		Write-Verbose "JobID specified ($JobID)- using Get-API instead of List-API..."
		$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/get?job_id=$JobID"
	}
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers

	return $result
}

Function Delete-DbJob
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Deletes the job and sends an email to the addresses specified in JobSettings.email_notifications. No action will occur if the job has already been removed. After the job is removed, neither its details or its run history will be visible via the Jobs UI or API. The job is guaranteed to be removed upon completion of this request. However, runs that were active before the receipt of this request may still be active. They will be terminated asynchronously.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#delete
			.PARAMETER JobID 
			The canonical identifier of the job to delete. This field is required.
			.EXAMPLE
			Delete-DbJob -JobID <JobID>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		job_id = $JobID 
	}
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Update-DbJob
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Overwrites the settings of a job with the provided settings.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#reset
			.PARAMETER Job_Id 
			The canonical identifier of the job to reset. This field is required.
			.PARAMETER New_Settings 
			The new settings of the job. These new settings replace the old settings entirely.
			Changes to the following fields are not applied to active runs: JobSettings.cluster_spec or JobSettings.task.
			Changes to the following fields are applied to active runs as well as future runs: JobSettings.timeout_second, JobSettings.email_notifications, or JobSettings.retry_policy. This field is required.
			.EXAMPLE
			Update-DbJob -JobID <JobID> -New_Settings <new_settings>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobID, 
		[Parameter(Mandatory = $true, Position = 2)] [object] $NewSettings
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/reset"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		job_id = $JobID 
		new_settings = $NewSettings 
	}
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Start-DbJob
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Runs the job now, and returns the run_id of the triggered run.
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
			.EXAMPLE
			Start-DbJob -JobID <JobID> -NotebookParams @{ param1 : 123, param2 : "MyTextParam" }
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobID, 
		[Parameter(Mandatory = $false, Position = 2)] [string[]] $JarParams = @(), 
		[Parameter(Mandatory = $false, Position = 3)] [hashtable] $NotebookParams = @(), 
		[Parameter(Mandatory = $false, Position = 4)] [string[]] $PythonParams = @(), 
		[Parameter(Mandatory = $false, Position = 5)] [string[]] $SparkSubmitParams = @()
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/run-now"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		job_id = $JobID 
	}
	
	if($JarParams.Count -gt 0) { $parameters.Add("jar_params", $JarParams) }
	if($NotebookParams.Count -gt 0) { $parameters.Add("notebook_params", $NotebookParams) }
	if($PythonParams.Count -gt 0) { $parameters.Add("python_params", $PythonParams) }
	if($SparkSubmitParams.Count -gt 0) { $parameters.Add("spark_submit_params", $SparkSubmitParams) }

	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Start-DbNotebook
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Submit a one-time run with the provided settings. This endpoint doesn't require a Databricks job to be created. You can directly submit your workload. Runs submitted via this endpoint don't show up in the UI. Once the run is submitted, you can use the jobs/runs/get API to check the run state.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-submit
			.PARAMETER ClusterID 
			If existing_cluster_id, the ID of an existing cluster that will be used for all runs of this job. When running jobs on an existing cluster, you may need to manually restart the cluster if it stops responding. We suggest running jobs on new clusters for greater reliability.
			If new_cluster, a description of a cluster that will be created for each run.
			.PARAMETER Path
			The Path of the notebook to execute.
			.PARAMETER NotebookParameters
			A hashtable containing the parameters to pass to the notebook
			.PARAMETER Name 
			An optional name for the run. The default value is Untitled.
			.PARAMETER Libraries 
			An optional list of libraries to be installed on the cluster that will execute the job. The default value is an empty list.
			.PARAMETER Timeout_Seconds 
			An optional timeout applied to each run of this job. The default behavior is to have no timeout.
			.EXAMPLE
			Start-DbNotebook -Existing_Cluster_Id OR New_Cluster <existing_cluster_id OR new_cluster> -Notebook_Task OR Spark_Jar_Task OR Spark_Python_Task OR Spark_Submit_Task <notebook_task OR spark_jar_task OR spark_python_task OR spark_submit_task> -Run_Name <run_name> -Libraries <libraries> -Timeout_Seconds <timeout_seconds>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $false, Position = 2)] [string] $Path, 
		[Parameter(Mandatory = $false, Position = 3)] [hashtable] $NotebookParameters, 
		[Parameter(Mandatory = $false, Position = 4)] [string] $Name, 
		[Parameter(Mandatory = $false, Position = 5)] [string[]] $Libraries, 
		[Parameter(Mandatory = $false, Position = 6)] [int32] $TimeoutSeconds
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/runs/submit"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	$notebookTask =  @{ notebook_path = $Path }
	$notebookTask | Add-Property  -Name "base_parameters" -Value $NotebookParameters

	#Set parameters
	$parameters = @{
		existing_cluster_id = $ClusterID
		notebook_task = $notebookTask
	}
	
	$parameters | Add-Property -Name "run_name" -Value $Name
	$parameters | Add-Property -Name "libraries" -Value $Libraries
	$parameters | Add-Property -Name "timeout_seconds" -Value $TimeoutSeconds

	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-DbJobRun
{
	<#
			.SYNOPSIS
			List the contents of a given path in a Databricks workspace
			.DESCRIPTION
			Lists runs from most recently started to least.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-list
			.PARAMETER JobID 
			The job for which to list runs. If omitted, the Jobs service will list runs from all jobs.
			.PARAMETER Active_Only OR Completed_Only 
			If active_only, if true, only active runs will be included in the results; otherwise, lists both active and completed runs.
			Note: This field cannot be true when completed_only is true.
			If completed_only, if true, only completed runs will be included in the results; otherwise, lists both active and completed runs.
			Note: This field cannot be true when active_only is true.
			
			.PARAMETER Offset 
			The offset of the first run to return, relative to the most recent run.
			.PARAMETER Limit 
			The number of runs to return. This value should be greater than 0 and less than 1000. The default value is 20. If a request specifies a limit of 0, the service will instead use the maximum limit.
			.EXAMPLE
			Get-DbJobRun -Active_Only OR Completed_Only <active_only OR completed_only> -JobID <JobID> -Offset <offset> -Limit <limit>
	#>
	[CmdletBinding(DefaultParametersetName = "ByJobId")]
	param
	(
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 1)] [int64] $JobID = -1, 
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 2)] [string] [ValidateSet("ActiveOnly", "CompletedOnly", "All")] $Filter = "All",
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 3)] [int32] $Offset = -1, 
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 4)] [int32] $Limit = -1,
		
		[Parameter(ParameterSetName = "ByRunId", Mandatory = $true, Position = 1)] [int64] $RunID
	)

	Test-Initialized
	
	Write-Verbose "Running with ParameterSet '$($PSCmdlet.ParameterSetName)' ..."

	Write-Verbose "Setting final ApiURL ..."
	switch ($PSCmdlet.ParameterSetName) 
	{ 
		"ByJobId"  { $apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/runs/list" } 
		"ByRunId"  { $apiUrl = Get-DbApiUrl -ApiEndpoint "/2.0/jobs/runs/get" } 
	} 
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-DbRequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	switch ($PSCmdlet.ParameterSetName) 
	{ 
		"ByJobId" {
			#Set parameters
			$parameters = @{}
			$parameters | Add-Property -Name "job_id" -Value $JobID -NullValue -1
			$parameters | Add-Property -Name "offset" -Value $Offset -NullValue -1 
			$parameters | Add-Property -Name "limit" -Value $Limit -NullValue -1
			
			if($Filter -eq "ActiveOnly") { $parameters | Add-Property -Name "active_only" -Value $true }
			if($Filter -eq "CompletedOnly") { $parameters | Add-Property -Name "completed_only" -Value $true }
		}

		"ByRunId" {
			#Set parameters
			$parameters = @{
				run_id = $RunID 
			}
		}
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}