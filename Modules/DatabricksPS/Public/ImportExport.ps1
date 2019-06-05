#requires -Version 3.0

$FolderNameWorkspace = "Workspace"
$FolderNameClusters = "Clusters"
$FolderNameJobs = "Jobs"

$ExportFormatToFileTypeMapping = @{
	"SOURCE" = "_DYNAMIC_"
	"HTML" = ".html"
	"JUPYTER" = ".ipynb"
	"DBC" = ".dbc"
	}

$LanguageToFileTypeMapping = @{
	"PYTHON" = ".py"
	"SQL" = ".sql"
	"SCALA" = ".scala"
	"R" = ".r"
	}

$ClusterPropertiesToKeep = @(       
	"cluster_name"
	"spark_version"
	"node_type_id"
	"driver_node_type_id"
	"spark_env_vars"
	"autotermination_minutes"
	"enable_elastic_disk"
	"autoscale"
	"fixed_size"
	"init_scripts_safe_mode"
	"spark_conf"
	"aws_attributes"
	"ssh_public_keys"
	"custom_tags"
	"cluster_log_conf"
	"init_scripts"
)

$NameIDSeparator = "__"

Function Export-DatabricksEnvironment
{
	<#
			.SYNOPSIS
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			.DESCRIPTION
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#delete
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.PARAMETER Recursive 
			The flag that specifies whether to delete the object recursively. It is false by default. Please note this deleting directory is not atomic. If it fails in the middle, some of objects under this directory may be deleted and cannot be undone.
			.EXAMPLE
			Remove-DatabricksWorkspaceItem -Path <Path> -Recursive $false
	#>
	[CmdletBinding(DefaultParametersetname = "AllArtifacts")]
	param
	(
		[Parameter(Mandatory = $true)] [string] $LocalPath,
		[Parameter(Mandatory = $false)] [switch] $CleanLocalPath,
		[Parameter(Mandatory = $false)] [string] $WorkspaceRootPath = "/",
		[Parameter(Mandatory = $false)] [string] [ValidateSet("SOURCE", "HTML", "JUPYTER", "DBC")] $WorkspaceExportFormat = "DBC",
		[Parameter(Mandatory = $true)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs")] $Artifacts
	)
	
	Write-Warning "This feature is EXPERIMENTAL and still UNDER DEVELOPMENT!"
	
	$LocalPath = $LocalPath.Trim("\")
	
	#region CleanLocalPath
	Write-Verbose "Checking if Folder '$LocalPath' exists ..."
	if((Test-Path $LocalPath) -and $CleanLocalPath)
	{
		Write-Verbose "Local folder '$LocalPath' exists and -CleanLocalPath is specified - deleting folder..."
		Remove-Item -Path $LocalPath -Recurse -Force
	}
	
	Write-Verbose "Creating local folder '$LocalPath' ..."
	$x = New-Item -ItemType Directory -Force -Path $LocalPath
	#endregion

	#region Export Workspace Items
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Workspace")
	{
		$LocalWorkspacePath = "$LocalPath\$FolderNameWorkspace"
		if(-not (Test-Path $LocalWorkspacePath))
		{
			Write-Verbose "Creating local folder '$LocalWorkspacePath' ..."
			$x = New-Item -ItemType Directory -Force -Path $LocalWorkspacePath
		}
	
		if($WorkspaceExportFormat -ne "SOURCE")
		{
			$globalExtension = $ExportFormatToFileTypeMapping[$WorkspaceExportFormat]
		}
	
		$rootFolders = Get-DatabricksWorkspaceItem -Path $WorkspaceRootPath -ChildItems
	
		foreach($rootFolder in $rootFolders)
		{
			$objectType = $rootFolder.object_type
			$itemPath = $rootFolder.path
		
			if($objectType -eq "NOTEBOOK")
			{
				Write-Information "NOTEBOOK  found at $itemPath - Exporting item ..."
				$item = Get-DatabricksWorkspaceItem -Path $itemPath
			
				if($globalExtension)
				{
					$extension = $globalExtension
				}
				else
				{
					$extension = $LanguageToFileTypeMapping[$item.language]
				}
			
				Export-DatabricksWorkspaceItem -LocalPath $($LocalWorkspacePath + $itemPath.Replace("/", "\") + $extension) -Path $itemPath -Format $WorkspaceExportFormat -CreateFolder
			}
			elseif($objectType -eq "DIRECTORY")
			{
				Write-Information "DIRECTORY found at $itemPath - Starting new iteration for WorkspaceItems only ..."
				Export-DatabricksEnvironment -LocalPath $LocalPath -WorkspaceRootPath $itemPath -WorkspaceExportFormat $WorkspaceExportFormat -Artifacts Workspace
			}
			elseif($objectType -eq "LIBRARY")
			{
				Write-Warning "LIBRARY   found at $itemPath - Exporting Libraries is currently not supported!"
			}
			else
			{
				throw "Workspace item Object Type $objectType under path $itemPath is not supported!"
			}
		}
	}
	#endregion
	
	#region Clusters
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Clusters")
	{
		$LocalClustersPath = "$LocalPath\$FolderNameClusters"
		if(-not (Test-Path $LocalClustersPath))
		{
			Write-Verbose "Creating local folder '$LocalClustersPath' ..."
			$x = New-Item -ItemType Directory -Force -Path $LocalClustersPath
		}
	
		$clusters = Get-DatabricksCluster
	
		foreach($cluster in $clusters)
		{
			Write-Information "Exporting cluster $($cluster.cluster_name) (ID: $($cluster.cluster_id)) ..."
			$clusterObject = @{}
		
			foreach($clusterProperty in $ClusterPropertiesToKeep)
			{
				if($cluster.psobject.properties.Item($clusterProperty))
				{
					$clusterObject | Add-Member -MemberType NoteProperty -Name $clusterProperty -Value $cluster.psobject.properties.Item($clusterProperty).Value
				}
			}
		
			$clusterObject | ConvertTo-Json -Depth 10 | Out-File $($LocalClustersPath + "\" + $cluster.cluster_name + $NameIDSeparator + $cluster.cluster_id + ".json")
		}
	}
	#endregion
	
	#region Jobs
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Jobs")
	{
		$LocalJobsPath = "$LocalPath\$FolderNameJobs"
		if(-not (Test-Path $LocalJobsPath))
		{
			Write-Verbose "Creating local folder '$LocalJobsPath' ..."
			$x = New-Item -ItemType Directory -Force -Path $LocalJobsPath
		}
	
		$jobs = Get-DatabricksJob
	
		foreach($job in $jobs)
		{
			Write-Information "Exporting job $($job.settings.name) (ID: $($job.job_id)) ..."
			if($job.settings.psobject.properties.Item("existing_cluster_id"))
			{
				# possible TODO during import as Cluster_ID will change!!!
			}
			$job.settings | ConvertTo-Json -Depth 10 | Out-File $($LocalJobsPath + "\" + $job.settings.name + $NameIDSeparator + $job.job_id + ".json")
		}
	}
	#endregion
}
		

Function Import-DatabricksEnvironment
{
	<#
			.SYNOPSIS
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			.DESCRIPTION
			Deletes an object or a directory (and optionally recursively deletes all objects in the directory). If path does not exist, this call returns an error RESOURCE_DOES_NOT_EXIST. If path is a non-empty directory and recursive is set to false, this call returns an error DIRECTORY_NOT_EMPTY. Object deletion cannot be undone and deleting a directory recursively is not atomic.
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#delete
			.PARAMETER Path 
			The absolute path of the notebook or directory. This field is required.
			.PARAMETER Recursive 
			The flag that specifies whether to delete the object recursively. It is false by default. Please note this deleting directory is not atomic. If it fails in the middle, some of objects under this directory may be deleted and cannot be undone.
			.EXAMPLE
			Remove-DatabricksWorkspaceItem -Path <Path> -Recursive $false
	#>
	[CmdletBinding(DefaultParametersetname = "AllArtifacts")]
	param
	(
		[Parameter(Mandatory = $true)] [string] $LocalPath,
		[Parameter(Mandatory = $true)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs")] $Artifacts	
	)
	
	Write-Warning "This feature is EXPERIMENTAL and still UNDER DEVELOPMENT!"

	$LocalPath = $LocalPath.Trim("\")
	
	#region Export Workspace Items
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Workspace")
	{
		if($LocalPath -like "*\$FolderNameWorkspace*")
		{
			$LocalWorkspacePath = $LocalPath	
		}
		else
		{
			$LocalWorkspacePath = "$LocalPath\$FolderNameWorkspace"
		}
		$LocalWorkspaceImportRootPath = $LocalWorkspacePath.Substring(0, $LocalWorkspacePath.IndexOf("\$FolderNameWorkspace")) + "\$FolderNameWorkspace"
		
		
		$workspaceItems = Get-ChildItem $LocalWorkspacePath
		
		foreach($workspaceItem in $workspaceItems)
		{
			$dbPath = $workspaceItem.FullName.Replace($LocalWorkspaceImportRootPath, "").Replace("\", "/")

			if($workspaceItem -is [System.IO.DirectoryInfo])
			{
				$x = Add-DatabricksWorkspaceDirectory -Path $dbPath
				$x = Import-DatabricksEnvironment -LocalPath $workspaceItem.FullName -Artifacts Workspace
			}
			if($workspaceItem -is [System.IO.FileInfo])
			{
				$dbPathItem = $dbPath.Replace($workspaceItem.Extension, "")
				$importParams = @{}
				$language = $LanguageToFileTypeMapping.GetEnumerator() | Where-Object { $_.Value -ieq $workspaceItem.Extension }
				if($language) { $importParams.Add("Language", $language.Key) }
				$format = $ExportFormatToFileTypeMapping.GetEnumerator() | Where-Object { $_.Value -ieq $workspaceItem.Extension }
				if($format) { $importParams.Add("Format", $format.Key) }
				
				$importParams.Add("Path", $dbPathItem)
				$importParams.Add("LocalPath", $workspaceItem.FullName)
				$x = Import-DatabricksWorkspaceItem @importParams
			}
		}
	}
	#endregion
	
	#region Clusters
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Clusters")
	{
		$LocalClustersPath = "$LocalPath\$FolderNameClusters"
		
		$clusterDefinitions = Get-ChildItem $LocalClustersPath
		
		foreach($clusterDefinition in $clusterDefinitions[0])
		{
			$clusterObject = Get-Content $clusterDefinition.FullName | ConvertFrom-Json
			
			$x = Add-DatabricksCluster -ClusterObject $clusterObject
		}
	}
	#endregion
	
	#region Jobs
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Jobs")
	{
		$LocalJobsPath = "$LocalPath\$FolderNameJobs"
		
		$jobDefinitions = Get-ChildItem $LocalJobsPath
		
		foreach($jobDefinition in $jobDefinitions)
		{
			$jobSettings = Get-Content $jobDefinition.FullName | ConvertFrom-Json
			
			$x = Add-DatabricksJob -JobSettings $jobSettings
		}
	}
	#endregion
}