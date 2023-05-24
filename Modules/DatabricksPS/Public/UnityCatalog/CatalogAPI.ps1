Function Get-UnityCatalogCatalog {
	<#
		.SYNOPSIS
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array.
		.DESCRIPTION
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array. 
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/catalogs/list
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/catalogs/get
		.PARAMETER CatalogName 
		The name of the catalog to retrieve. This field is optional and can be used as a filter on one particular catalog.
		.EXAMPLE
		Get-UnityCatalogCatalog -CatalogName MyCatalog
		.EXAMPLE
		#AUTOMATED_TEST:List existing Unity Catalogs
		Get-UnityCatalogCatalog
	#>
	param 
	(	
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("name", "catalog_name")] [string] $CatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Raw
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.1/unity-catalog/catalogs"
	}	
	process {
		If($PSBoundParameters.ContainsKey("CatalogName")) {
			$apiEndpoint = "/2.1/unity-catalog/catalogs/$CatalogName"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSBoundParameters.ContainsKey("CatalogName") -or $Raw.IsPresent) {
			# if a CatalogName was specified, we return the result as it is
			return $result
		}
		else {
			# if no CatalogName was specified, we return the catalogs as an array
			return $result.catalogs
		}
	}
}

Function Add-UnityCatalogCatalog {
	<#
		.SYNOPSIS
		Creates a repo in the workspace and links it to the remote Git repo specified. Note that repos created programmatically must be linked to a remote Git repo, unlike repos created in the browser.
		.DESCRIPTION
		Creates a repo in the workspace and links it to the remote Git repo specified. Note that repos created programmatically must be linked to a remote Git repo, unlike repos created in the browser.
		https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/create-repo
		.PARAMETER URL 
		URL of the Git repository to be linked.
		.PARAMETER Provider 
		Git provider. This field is case-insensitive. The available Git providers are gitHub, bitbucketCloud, gitLab, azureDevOpsServices, gitHubEnterprise, bitbucketServer and gitLabEnterpriseEdition.
		.PARAMETER Path 
		Desired path for the repo in the workspace. Must be in the format /Repos/{folder}/{repo-name}.
		.EXAMPLE
		Add-UnityCatalogCatalog -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "catalog_name")]$CatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("storage_root")]$StorageRoot,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("provider_name")]$ProviderName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [hashtable] $Properties,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("share", "share_name")]$ShareName
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.1/unity-catalog/catalogs"
	}
		
	process {    
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			name    = $CatalogName
		}

		$parameters | Add-Property -Name "storage_root" -Value $StorageRoot -Force
		$parameters | Add-Property -Name "provider_name" -Value $ProviderName -Force
		$parameters | Add-Property -Name "properties" -Value $Properties -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force
		$parameters | Add-Property -Name "share_name" -Value $ShareName -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Update-UnityCatalogCatalog {
	<#
		.SYNOPSIS
		Updates the repo to the given branch or tag.
		.DESCRIPTION
		Updates the repo to the given branch or tag. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/update-repo
		.PARAMETER CatalogName 
		The ID for the corresponding repo to access.
		.PARAMETER Branch
		Branch that the local version of the repo is checked out to.
		.PARAMETER Tag
		Tag that the local version of the repo is checked out to. Updating the repo to a tag puts the repo in a detached HEAD state. Before committing new changes, you must update the repo to a branch instead of the detached HEAD.
		.EXAMPLE
		Update-UnityCatalogCatalog -CatalogName 123 -Branch "main"
		.EXAMPLE
		Update-UnityCatalogCatalog -CatalogName 123 -Tag "v2.3.1"
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "catalog_name")]$CatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("new_name", "new_catalog_name")]$NewCatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Owner,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [ValidateSet("OPEN", "ISOLATED")][Alias("isolation_Mode")]$IsolationMode,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [hashtable] $Properties,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment
	)
	begin {
		$requestMethod = "PATCH"
	}	
	process {
		$apiEndpoint = "/2.1/unity-catalog/catalogs/$CatalogName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$parameters | Add-Property -Name "name" -Value $NewCatalogName -Force
		$parameters | Add-Property -Name "owner" -Value $Owner -Force
		$parameters | Add-Property -Name "isolation_mode" -Value $IsolationMode -Force
		$parameters | Add-Property -Name "properties" -Value $Properties -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Remove-UnityCatalogCatalog {
	<#
		.SYNOPSIS
		Deletes the specified repo.
		.DESCRIPTION
		Deletes the specified repo. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/delete-repo
		.PARAMETER CatalogName 
		The ID for the corresponding repo to delete.
		.EXAMPLE
		Delete-UnityCatalogCatalog -CatalogName 123
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "catalog_name")]$CatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
	)
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.1/unity-catalog/catalogs/$CatalogName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ 
			force = $Force.IsPresent
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}