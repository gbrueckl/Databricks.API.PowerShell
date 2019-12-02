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
			Exports the selected items of the Databricks workspace to a local path from where it can be imported again to a different Databricks workspace using Import-DatabricksEnvironment.
			.DESCRIPTION
			Exports the selected items of the Databricks workspace to a local path from where it can be imported again to a different Databricks workspace using Import-DatabricksEnvironment.
			.PARAMETER LocalPath 
			The local path where the export should be stored.
			.PARAMETER Artifacts
			A list of objects that you want to export. The default is 'All' but you can also specify a list of artifacts like 'Clusters,Jobs,Secrets'
			.PARAMETER CleanLocalPath 
			The switch that can be used to clean the lcoal path before exporting the new content.
			.PARAMETER WorkspaceRootPath 
			The path of your workspace folder structure from which you want to start to recursivly export the files and folders in case you do not want to export all notebooks.
			.PARAMETER WorkspaceExportFormat
			The format in which the workspace items (=notebooks) should be exported. The default is 'DBC' which is also highly recommended if they are imported to another Databricks workspace again!
			.EXAMPLE
			Export-DatabricksEnvironment -LocalPath 'C:\MyExport\' -CleanLocalPath
	#>
	param
	(
		[Parameter(Mandatory = $true)] [string] $LocalPath,
		[Parameter(Mandatory = $false)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs", "Security", "Secrets")] $Artifacts = @("All"),
		[Parameter(Mandatory = $false)] [switch] $CleanLocalPath,
		[Parameter(Mandatory = $false)] [string] $WorkspaceRootPath = "/",
		[Parameter(Mandatory = $false)] [string] [ValidateSet("SOURCE", "HTML", "JUPYTER", "DBC")] $WorkspaceExportFormat = "DBC",
		[Parameter(Mandatory = $false)] [switch] $ExportJobClusters
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
		
		if(-not $ExportJobClusters)
		{
			$clusters = $clusters | Where-Object { $_.cluster_source -ne "JOB" }
		}
	
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
			Imports Databricks content which was created using Export-DatabricksEnvironment from a local path into the Databricks service.
			.DESCRIPTION
			Imports Databricks content which was created using Export-DatabricksEnvironment from a local path into the Databricks service.
			.PARAMETER LocalPath 
			The local path where the export is located.
			.PARAMETER Artifacts
			A list of objects that you want to export. The default is 'All' but you can also specify a list of artifacts like 'Clusters,Jobs,Secrets'
			.PARAMETER OverwriteExistingWorkspaceItems 
			A switch that can be used to overwrite existing workspace items (=notebooks) during the import..
			.PARAMETER UpdateExistingClusters 
			A swicht that can be used to force an update of existing clusters. By default existing clusters will not be changed/updated! 
			.PARAMETER UpdateExistingJobs
			A switch that can be used to force an update of existing Jobs. By default existing jobs will not be changed/updated!
			.PARAMETER PromptForMissingSecrets
			A switch that can be used to prompt the user when a secret is missing in the target and no new values have been specified within the export using the properties "new_string_value" or "new_bytes_value".
			.PARAMETER UpdateExistingSecrets
			A switch that can be used to force an update of an existing secret's value. The new secret is specified in the JSON by adding one of the following new properties: "new_strign_value" or "new_bytes_value".
			.EXAMPLE
			Export-DatabricksEnvironment -LocalPath 'C:\MyExport\' -CleanLocalPath
	#>
	[CmdletBinding(DefaultParametersetname = "AllArtifacts")]
	param
	(
		[Parameter(Mandatory = $true)] [string] $LocalPath,
		[Parameter(Mandatory = $false)] [string[]] [ValidateSet("All", "Workspace", "Clusters", "Jobs", "Security", "Secrets")] $Artifacts = @("All"),
		[Parameter(Mandatory = $false)] [switch] $OverwriteExistingWorkspaceItems,
		[Parameter(Mandatory = $false)] [switch] $UpdateExistingClusters,
		[Parameter(Mandatory = $false)] [switch] $UpdateExistingJobs,
		[Parameter(Mandatory = $false)] [switch] $PromptForMissingSecrets,
		[Parameter(Mandatory = $false)] [switch] $UpdateExistingSecrets
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
						$x = Import-DatabricksEnvironment -LocalPath $workspaceItem.FullName -Artifacts Workspace -OverwriteExistingWorkspaceItems:$OverwriteExistingWorkspaceItems -UpdateExistingClusters:$UpdateExistingClusters -UpdateExistingJobs:$UpdateExistingJobs
					}
					else
					{ 
						Write-Information "Importing Workspace item $($workspaceItem.Name) ..."
						$x = Add-DatabricksWorkspaceDirectory -Path $dbPath -ErrorAction Ignore
						$x = Import-DatabricksEnvironment -LocalPath $workspaceItem.FullName -Artifacts Workspace -OverwriteExistingWorkspaceItems:$OverwriteExistingWorkspaceItems -UpdateExistingClusters:$UpdateExistingClusters -UpdateExistingJobs:$UpdateExistingJobs
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
					if((Get-DatabricksWorkspaceItem -Path $dbPathItem -ErrorAction SilentlyContinue) -and $OverwriteExistingWorkspaceItems) 
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
					if($UpdateExistingClusters)
					{
						$x = Update-DatabricksCluster -ClusterObject $clusterObject
					}
					else
					{
						Write-Information "    Cluster '$($clusterObject.cluster_name)' already exists. Use parameter -UpdateExistingClusters to udpate existing clusters!"
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
					if($UpdateExistingJobs)
					{
						$x = Update-DatabricksJob -NewSettingsbject $jobSettings
					}
					else
					{
						Write-Information "    Job '$($jobSettings.name)' already exists. Use parameter -UpdateExistingJobs to udpate existing jobs!"
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
	
			$existingScopes = Get-DatabricksSecretScope
			foreach($secretScopeDefinition in $secretScopeDefinitions)
			{
				$secretScope = Get-Content $secretScopeDefinition.FullName | ConvertFrom-Json
				Write-Information "Adding secret scope $($secretScope.scope) ..."
			
				if($secretScope.backend_type -eq 'DATABRICKS')
				{
					if($secretScope.scope -in $existingScopes.name)
					{
						Write-Information "Secret scope $($secretScope.scope) already exists!"
					}
					else
					{
						Add-DatabricksSecretScope -ScopeName $secretScope.scope -InitialManagePrincipal $secretScope.initial_manage_principal -ErrorAction Continue
					}
					
					$secretScope.acls | Add-DatabricksSecretScopeACL -ScopeName $secretScope.scope
				
					$currentSecrets = Get-DatabricksSecret -ScopeName $secretScope.scope
				
					foreach($secret in $secretScope.secrets)
					{
						$isMissingInTarget = $secret.key -cnotin $currentSecrets.key
						$newValueProvided = -not ([string]::IsNullOrEmpty($secret.new_string_value) -and [string]::IsNullOrEmpty($secret.new_bytes_value))
						
						if($isMissingInTarget)
						{
							if($newValueProvided)
							{
								Write-Information "A new Secret '$($secret.key)' is added"
								$secret | Add-DatabricksSecret -ScopeName $secretScope.scope
							}
							else
							{
								if($PromptForMissingSecrets)
								{
									Write-Host "Please enter a value for secret '$($secret.key)': "
									$newSecretValue = Read-Host -Prompt "$($secret.key)"
									Add-DatabricksSecret -ScopeName $secretScope.scope -SecretName $secret.key -StringValue $newSecretValue
								}
								else
								{
									Write-Warning "The secret '$($secret.key)' of scope $($secretScope.scope) is missing in the target - please add it manually or use parameter -PromptForMissingSecrets"
								}
							}							
						}
						else
						{
							if($newValueProvided)
							{
								if($UpdateExistingSecrets)
								{
									Write-Information "Secret '$($secret.key)' is updated uing the provided value in the JSON file."
									$secret | Add-DatabricksSecret -ScopeName $secretScope.scope
								}
								else
								{
									Write-Information "Secret '$($secret.key)' already exists. Use -UpdateExistingSecrets to update its value with the one specified in the JSON."
								}
							}
							else
							{
								Write-Information "Secret '$($secret.key)' already exists and no update was requested."
							}
						}
					}
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