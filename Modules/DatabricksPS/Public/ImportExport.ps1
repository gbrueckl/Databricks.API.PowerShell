#requires -Version 3.0

$FolderNameWorkspace = "Workspace"
$FolderNameClusters = "Clusters"
$FolderNameJobs = "Jobs"
$FolderNameSecurity = "Security"
$FolderNameSecrets = "Secrets"

$NameIDSeparator = "__"
$ExistingClusterNameTag = "existing_cluster_name"


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
	"num_workers"
	"fixed_size"
	"init_scripts_safe_mode"
	"spark_conf"
	"aws_attributes"
	"ssh_public_keys"
	"custom_tags"
	"cluster_log_conf"
	"init_scripts"
)



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
		[Parameter(Mandatory = $false)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs", "Security", "Secrets")] $Artifacts = @("All")
	)
	
	if($Artifacts -ne @("Workspace"))
	{
		Write-Warning "This feature is EXPERIMENTAL and still UNDER DEVELOPMENT!"
	}	
	$LocalPath = $LocalPath.Trim("\")
	
	#region CleanLocalPath
	Write-Verbose "Checking if Folder '$LocalPath' exists ..."
	if((Test-Path $LocalPath) -and $CleanLocalPath)
	{
		Write-Verbose "Local folder '$LocalPath' exists and -CleanLocalPath is specified - deleting folder..."
		Remove-Item -Path $LocalPath -Recurse -Force -ErrorAction SilentlyContinue
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
				$x = New-Item -ItemType Directory -Force -Path (Join-Path $LocalWorkspacePath -ChildPath $itemPath)
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
				# we need to add the name of the existing cluster so we can map it again to the right cluster in the new environment
				$jobCluster = Get-DatabricksCluster -ClusterID $job.settings.existing_cluster_id
				Add-Member -InputObject $job.settings -MemberType NoteProperty -Name $ExistingClusterNameTag -Value $jobCluster.cluster_name
			}
			$job.settings | ConvertTo-Json -Depth 10 | Out-File $($LocalJobsPath + "\" + $job.settings.name + $NameIDSeparator + $job.job_id + ".json")
		}
	}
	#endregion
	
	#region Security
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Security")
	{
		$LocalSecurityPath = "$LocalPath\$FolderNameSecurity"
		if(-not (Test-Path $LocalSecurityPath))
		{
			Write-Verbose "Creating local folder '$LocalSecurityPath' ..."
			$x = New-Item -ItemType Directory -Force -Path $LocalSecurityPath
		}
	
		$groups = Get-DatabricksGroup
	
		foreach($group in $groups)
		{
			Write-Information "Exporting group $group ..."
			$members = Get-DatabricksGroupMember -GroupName $group
			
			$members | ConvertTo-Json -Depth 10 | Out-File $($LocalSecurityPath + "\" + $group + ".json")
		}
	}
	#endregion
	
	#region Secrets
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Secrets")
	{
		Write-Warning "It is not possible to extract secret values via the Databricks REST API.`nThis export only exports the names of SecretScopes and their Secrets but not the values!"
		$LocalSecretsPath = "$LocalPath\$FolderNameSecrets"
		if(-not (Test-Path $LocalSecretsPath))
		{
			Write-Verbose "Creating local folder '$LocalSecretsPath' ..."
			$x = New-Item -ItemType Directory -Force -Path $LocalSecretsPath
		}
	
		$secretScopes = Get-DatabricksSecretScope
	
		foreach($secretScope in $secretScopes)
		{
			Write-Information "Exporting secret scope $($secretScope.name) ..."
			$secrets = @()
			Get-DatabricksSecret -ScopeName $secretScope.name | ForEach-Object { $secrets += $_ }
			
			$acls = Get-DatabricksSecretScopeACL -ScopeName $secretScope.name
			
			$managePrincipals = @()
			$acls | Where-Object { $_.permission -eq "MANAGE" } | ForEach-Object { $managePrincipals += $_ }
			$managePrincipals += '{"principal": "users", "permission": "MANAGE"}' | ConvertFrom-Json # add default principal 
			
			$output = @{
				"scope" = $secretScope.name
				"backend_type" = $secretScope.backend_type
				"initial_manage_principal" = $managePrincipals[0].principal
				"secrets" = $secrets
				"acls" = $acls
			}
			$output | ConvertTo-Json -Depth 10 | Out-File $($LocalSecretsPath + "\" + $secretScope.name + ".json")
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
		[Parameter(Mandatory = $false)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs", "Security", "Secrets")] $Artifacts = @("All"),
		[Parameter(Mandatory = $false)] [switch] $WorkspaceOverwriteExistingItems,
		[Parameter(Mandatory = $false)] [switch] $ClusterUpdateExisting,
		[Parameter(Mandatory = $false)] [switch] $JobUpdateExisting
	)

	if($Artifacts -ne @("Workspace"))
	{
		Write-Warning "This feature is EXPERIMENTAL and still UNDER DEVELOPMENT!"
	}
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
		Write-Information "Importing Workspace content from $LocalWorkspacePath ..."
		
		if(-not (Test-Path -Path $LocalWorkspaceImportRootPath))
		{
			Write-Warning "The export does not contain any Workspaces - step is skipped!"
		}
		else
		{
			$workspaceItems = Get-ChildItem $LocalWorkspacePath
		
			foreach($workspaceItem in $workspaceItems)
			{
				$dbPath = $workspaceItem.FullName.Replace($LocalWorkspaceImportRootPath, "").Replace("\", "/")

				if($workspaceItem -is [System.IO.DirectoryInfo])
				{
					if($workspaceItem.BaseName -eq 'users')
					{
						Write-Warning "The folder '/users' is protected and cannot be created during imported!"
						$x = Import-DatabricksEnvironment -LocalPath $workspaceItem.FullName -Artifacts Workspace -WorkspaceOverwriteExistingItems:$WorkspaceOverwriteExistingItems -ClusterUpdateExisting:$ClusterUpdateExisting -JobUpdateExisting:$JobUpdateExisting
					}
					else
					{ 
						Write-Information "Importing Workspace item $($workspaceItem.Name) ..."
						$x = Add-DatabricksWorkspaceDirectory -Path $dbPath -ErrorAction Ignore
						$x = Import-DatabricksEnvironment -LocalPath $workspaceItem.FullName -Artifacts Workspace -WorkspaceOverwriteExistingItems:$WorkspaceOverwriteExistingItems -ClusterUpdateExisting:$ClusterUpdateExisting -JobUpdateExisting:$JobUpdateExisting
					}
				}
				elseif($workspaceItem -is [System.IO.FileInfo])
				{
					$dbPathItem = $dbPath.Replace($workspaceItem.Extension, "")
					$importParams = @{}
					$language = $LanguageToFileTypeMapping.GetEnumerator() | Where-Object { $_.Value -ieq $workspaceItem.Extension }
					if($language) { $importParams.Add("Language", $language.Key) }
					$format = $ExportFormatToFileTypeMapping.GetEnumerator() | Where-Object { $_.Value -ieq $workspaceItem.Extension }
					if($format) { $importParams.Add("Format", $format.Key) }
					if((Get-DatabricksWorkspaceItem -Path $dbPathItem -ErrorAction SilentlyContinue) -and $WorkspaceOverwriteExistingItems) 
					{ 
						Write-Verbose "Removing existing item $dbPathItem ..."
						Remove-DatabricksWorkspaceItem -Path $dbPathItem -Recursive $false
						#$importParams.Add("Overwrite", $true) # cannot be used with DBC
					}
				
					$importParams.Add("Path", $dbPathItem)
					$importParams.Add("LocalPath", $workspaceItem.FullName)
					$x = Import-DatabricksWorkspaceItem @importParams
				}
			}
		}
	}
	#endregion
	
	#region Clusters
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Clusters")
	{
		$LocalClustersPath = "$LocalPath\$FolderNameClusters"
		Write-Information "Importing Clusters from $LocalClustersPath ..."
		
		if(-not (Test-Path -Path $LocalClustersPath))
		{
			Write-Warning "The export does not contain any Clusters - step is skipped!"
		}
		else
		{
			$existingClusters = Get-DatabricksCluster
				
			$clusterDefinitions = Get-ChildItem $LocalClustersPath
		
			foreach($clusterDefinition in $clusterDefinitions)
			{
				Write-Information "Reading Cluster from $($clusterDefinition.Name) ..."
				$clusterObject = Get-Content $clusterDefinition.FullName | ConvertFrom-Json
			
				if($clusterObject.cluster_name -cnotin $existingClusters.cluster_name)
				{
					Write-Information "    Adding new Cluster '$($clusterObject.cluster_name)' ..."
					$x = Add-DatabricksCluster -ClusterObject $clusterObject
				}
				else
				{
					if($ClusterUpdateExisting)
					{
						$x = Update-DatabricksCluster -ClusterObject $clusterObject
					}
					else
					{
						Write-Information "    Cluster '$($clusterObject.cluster_name)' already exists. Use parameter -ClusterUpdateExisting to udpate existing clusters!"
					}
				}
			}
		}
	}
	#endregion
	
	#region Jobs
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Jobs")
	{
		$LocalJobsPath = "$LocalPath\$FolderNameJobs"
		Write-Information "Importing Jobs from $LocalJobsPath ..."
		
		if(-not (Test-Path -Path $LocalJobsPath))
		{
			Write-Warning "The export does not contain any Jobs - step is skipped!"
		}
		else
		{
			$existingJobs = Get-DatabricksJob
			$existingClusters = Get-DatabricksCluster
		
			$jobDefinitions = Get-ChildItem $LocalJobsPath
		
			foreach($jobDefinition in $jobDefinitions)
			{
				Write-Information "Reading Job from $($jobDefinition.Name) ..."
				$jobSettings = Get-Content $jobDefinition.FullName | ConvertFrom-Json
		
				if($ExistingClusterNameTag -in $jobSettings.psobject.Properties.Name)
				{
					$jobCluster = $existingClusters | Where-Object { $_.cluster_name -eq $jobSettings.psobject.Properties[$ExistingClusterNameTag].Value }
					$jobSettings.existing_cluster_id = $jobCluster[0].cluster_id
				}
			
				if($jobSettings.name -cnotin $existingJobs.settings.name)
				{
					Write-Information "    Adding new Job '$($jobSettings.name)' ..."
					$x = Add-DatabricksJob -JobSettings $jobSettings
				}
				else
				{
					if($JobUpdateExisting)
					{
						$x = Update-DatabricksJob -NewSettingsbject $jobSettings
					}
					else
					{
						Write-Information "    Job '$($jobSettings.name)' already exists. Use parameter -JobUpdateExisting to udpate existing jobs!"
					}
				}
			}
		}
	}
	#endregion
	
	#region Security
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Security")
	{
		$LocalSecurityPath = "$LocalPath\$FolderNameSecurity"
		Write-Information "Importing Security from $LocalSecurityPath ..."
		
		if(-not (Test-Path -Path $LocalSecurityPath))
		{
			Write-Warning "The export does not contain any Security-Information - step is skipped!"
		}
		else
		{
			$groupDefinitions = Get-ChildItem $LocalSecurityPath
	
			Write-Information "Creating empty security groups ..."
			$groupDefinitions.BaseName | Where-Object { $_ -ne "admins" } | Add-DatabricksGroup -ErrorAction SilentlyContinue
	
			foreach($groupDefinition in $groupDefinitions)
			{
				Write-Information "Adding members to group $($groupDefinition.BaseName) ..."
				$groupMembers = Get-Content $groupDefinition.FullName | ConvertFrom-Json
			
				$groupMembers | Add-DatabricksGroupMember -ParentGroupName $groupDefinition.BaseName
			}
		}
	}
	#endregion
	
	#region Secrets
	if($Artifacts -contains "All" -or $Artifacts -ccontains "Secrets")
	{
		$LocalSecretsPath = "$LocalPath\$FolderNameSecrets"
		Write-Information "Importing Secrets from $LocalSecretsPath ..."

		if(-not (Test-Path -Path $LocalSecretsPath))
		{
			Write-Warning "The export does not contain any Secrets - step is skipped!"
		}
		else
		{
			$secretScopeDefinitions = Get-ChildItem $LocalSecretsPath
	
			foreach($secretScopeDefinition in $secretScopeDefinitions)
			{
				Write-Information "Adding secret scope $($secretScopeDefinition.Name) ..."
				$secretScope = Get-Content $secretScopeDefinition.FullName | ConvertFrom-Json
			
				if($secretScope.backend_type -eq 'DATABRICKS')
				{
					Add-DatabricksSecretScope -ScopeName $secretScope.scope -InitialManagePrincipal $secretScope.initial_manage_principal -ErrorAction Continue
				
					$secretScope.acls | Add-DatabricksSecretScopeACL -ScopeName $secretScope.scope
				
					$currentSecrets = Get-DatabricksSecret -ScopeName $secretScope.scope
				
					$missingSecrets = $secretScope.secrets | Where-Object { $_.key -cnotin $currentSecrets.key -and [string]::IsNullOrEmpty($_.new_string_value) -and [string]::IsNullOrEmpty($_.new_byte_value) } | ForEach-Object {
						Write-Warning "The secret $($_.key) of scope $($secretScope.scope) is missing in the target - please add it manually!"
					}
					
					$secretScope.secrets | Where-Object { -not [string]::IsNullOrEmpty($_.new_string_value) -or -not [string]::IsNullOrEmpty($_.new_byte_value) } | Add-DatabricksSecret -ScopeName $secretScope.scope
				}
				else
				{
					Write-Warning "Currently only secret scopes stored in Databricks are supported!`nSkipping secret scope $($secretScopeDefinition.Name) ..."
				}
			}
		}
	}
	#endregion
}