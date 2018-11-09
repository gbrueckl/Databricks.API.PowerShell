#requires -Version 3.0
Function Get-Job
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
			.EXAMPLE
			Get-Job -JobID <JobID>
	#>
	[CmdletBinding()]
	param 
	(	
		[Parameter(Mandatory = $false, Position = 1)] [int64] $JobID = -1
	)

	Test-Initialized	 

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/list"
	if($JobID -ne -1)
	{
		Write-Verbose "JobID specified ($JobID)- using Get-API instead of List-API..."
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/get?job_id=$JobID"
	}
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers

	return $result
}

Function Remove-Job
{
	<#
			.SYNOPSIS
			Deletes the job and sends an email to the addresses specified in JobSettings.email_notifications. No action will occur if the job has already been removed. After the job is removed, neither its details or its run history will be visible via the Jobs UI or API. The job is guaranteed to be removed upon completion of this request. However, runs that were active before the receipt of this request may still be active. They will be terminated asynchronously.
			.DESCRIPTION
			Deletes the job and sends an email to the addresses specified in JobSettings.email_notifications. No action will occur if the job has already been removed. After the job is removed, neither its details or its run history will be visible via the Jobs UI or API. The job is guaranteed to be removed upon completion of this request. However, runs that were active before the receipt of this request may still be active. They will be terminated asynchronously.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#delete
			.PARAMETER JobID 
			The canonical identifier of the job to delete. This field is required.
			.EXAMPLE
			Remove-Job -JobID <JobID>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		job_id = $JobID 
	}
	
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Update-Job
{
	<#
			.SYNOPSIS
			Overwrites the settings of a job with the provided settings.
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
			Update-Job -JobID 1 -NewSettings <new_settings>
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobID, 
		[Parameter(Mandatory = $true, Position = 2)] [object] $NewSettings
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/reset"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

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


Function Start-Job
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
			.EXAMPLE
			Start-Job -JobID <JobID> -NotebookParams @{ param1 : 123, param2 : "MyTextParam" }
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
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/run-now"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		job_id = $JobID 
	}
	
	$parameters | Add-Property  -Name "jar_params" -Value $JarParams
	$parameters | Add-Property  -Name "notebook_params" -Value $NotebookParams
	$parameters | Add-Property  -Name "python_params" -Value $PythonParams
	$parameters | Add-Property  -Name "spark_submit_params" -Value $SparkSubmitParams

	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function New-JobRun
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
			.PARAMETER Timeout_Seconds 
			An optional timeout applied to each run of this job. The default behavior is to have no timeout.
			.EXAMPLE
			New-JobRun -ClusterID "1234-asdfae-1234" -NotebookPath "/Shared/MyNotebook" -RunName "MyJobRun" -TimeoutSeconds 300
	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "NotebookJob", Mandatory = $true)]
		[Parameter(ParameterSetName = "PythonkJob", Mandatory = $true)]
		[Parameter(ParameterSetName = "JarJob", Mandatory = $true)]
		[Parameter(ParameterSetName = "SparkJob", Mandatory = $true)] [int32] $JobID,
		
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
		[Parameter(ParameterSetName = "SparkJob", Mandatory = $true, Position = 2)] [string] $SparkParameters, 
		
		# generic parameters
		[Parameter(Mandatory = $false, Position = 1)] [string] $ClusterID, 
		[Parameter(Mandatory = $false, Position = 4)] [string] $RunName, 
		[Parameter(Mandatory = $false, Position = 5)] [string[]] $Libraries, 
		[Parameter(Mandatory = $false, Position = 6)] [int32] $TimeoutSeconds
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	if($PSCmdlet.ParameterSetName.EndsWith("Job"))
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/now"
	}
	else
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/submit"
	}
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
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
	$parameters | Add-Property -Name "timeout_seconds" -Value $TimeoutSeconds

	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-JobRun
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
			Get-JobRun -Active_Only OR Completed_Only <active_only OR completed_only> -JobID <JobID> -Offset <offset> -Limit <limit>
	#>
	[CmdletBinding(DefaultParametersetName = "ByJobId")]
	param
	(
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 1)] [int64] $JobID = -1, 
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 2)] [string] [ValidateSet("ActiveOnly", "CompletedOnly", "All")] $Filter = "All",
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 3)] [int32] $Offset = -1, 
		[Parameter(ParameterSetName = "ByJobId", Mandatory = $false, Position = 4)] [int32] $Limit = -1,
		
		[Parameter(ParameterSetName = "ByRunId", Mandatory = $true, Position = 1)] [int64] $JobRunID
	)

	Test-Initialized
	
	Write-Verbose "Running with ParameterSet '$($PSCmdlet.ParameterSetName)' ..."

	Write-Verbose "Setting final ApiURL ..."
	switch ($PSCmdlet.ParameterSetName) 
	{ 
		"ByJobId"  { $apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/list" } 
		"ByRunId"  { $apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/get" } 
	} 
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

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
				run_id = $JobRunID 
			}
		}
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Export-JobRun
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
			.EXAMPLE
			Export-JobRun -JobRunID 1 -ViewsToExport All
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobRunId, 
		[Parameter(Mandatory = $false, Position = 2)] [string] [ValidateSet("Code", "Dashboards", "All")] $ViewsToExport = "All"
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/export"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		run_id = $JobRunID 
		views_to_export = $ViewsToExport 
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Cancel-JobRun
{
	<#
			.SYNOPSIS
			Cancels a run. The run is canceled asynchronously, so when this request completes the run may be still be active. The run will be terminated as soon as possible.
			.DESCRIPTION
			Cancels a run. The run is canceled asynchronously, so when this request completes, the run may still be running. The run will be terminated shortly. If the run is already in a terminal life_cycle_state, this method is a no-op.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-cancel
			.PARAMETER JobRunID 
			The canonical identifier for the run to cancel. This field is required.
			.EXAMPLE
			Cancel-JobRun -JobRunID 1
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobRunID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/cancel"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		run_id = $JobRunID 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-JobRunOutput
{
	<#
			.SYNOPSIS
			Retrieves both the output and the metadata of a run.
			.DESCRIPTION
			Retrieve the output of a run. When a notebook task returns value through the dbutils.notebook.exit() call, you can use this endpoint to retrieve that value. Databricks restricts this API to return the first 5 MB of the output. For returning a larger result, you can store job results in a cloud storage service.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-get-output
			.PARAMETER JobRunID 
			The canonical identifier for the run. This field is required.
			.EXAMPLE
			Get-JobRunOutput -JobRunID 1
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [int64] $JobRunID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/get-output"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		run_id = $JobRunID 
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Remove-JobRun
{
	<#
			.SYNOPSIS
			Deletes a non-active run. Returns an error if the run is active.
			.DESCRIPTION
			Deletes a non-active run. Returns an error if the run is active.
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#runs-delete
			.PARAMETER JobRunID 
			The canonical identifier of the run for which to retrieve the metadata.
			.EXAMPLE
			Remove-JobRun -JobRunID 1
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [int64] $JobRunID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/jobs/runs/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		run_id = $JobRunID 
	}
			
	$parameters = $parameters | ConvertTo-Json

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}