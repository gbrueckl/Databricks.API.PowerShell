Function Get-UnityCatalogExternalLocation {
	<#
		.SYNOPSIS
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array.
		.DESCRIPTION
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array. 
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/external-locations/list
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/external-locations/get
		.PARAMETER CatalogName 
		The name of the catalog to retrieve. This field is optional and can be used as a filter on one particular catalog.
		.EXAMPLE
		Get-UnityCatalogExternalLocation -CatalogName MyCatalog
		.EXAMPLE
		#AUTOMATED_TEST:List existing Unity Catalogs
		Get-UnityCatalogExternalLocation
	#>
	param 
	(	
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("name", "external_location_name")] [string] $ExternalLocationName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Raw
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.1/unity-catalog/external-locations"
	}	
	process {
		If($PSBoundParameters.ContainsKey("ExternalLocationName")) {
			$apiEndpoint = "/2.1/unity-catalog/external-locations/$ExternalLocationName"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSBoundParameters.ContainsKey("ExternalLocationName") -or $Raw.IsPresent) {
			# if a CatalogName was specified, we return the result as it is
			return $result
		}
		else {
			# if no CatalogName was specified, we return the catalogs as an array
			return $result.external_locations
		}
	}
}

Function Add-UnityCatalogExternalLocation {
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
		Add-UnityCatalogExternalLocation -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "external_location_name")]$ExternalLocationName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] [Alias("skip_validation")]$SkipValidation,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [boolean] [Alias("read_only")]$ReadOnly,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("path")]$URL,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("credential_name")]$CredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.1/unity-catalog/external-locations"
	}
		
	process {    
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			name    = $ExternalLocationName
			url = $URL
			credential_name = $CredentialName
		}

		$parameters | Add-Property -Name "skip_validation" -Value $SkipValidation.IsPresent -Force
		$parameters | Add-Property -Name "read_only" -Value $ReadOnly -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force

		
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Update-UnityCatalogExternalLocation {
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
		Update-UnityCatalogExternalLocation -CatalogName 123 -Branch "main"
		.EXAMPLE
		Update-UnityCatalogExternalLocation -CatalogName 123 -Tag "v2.3.1"
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "external_location_name")]$ExternalLocationName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("new_name", "new_external_location_name")]$NewExternalLocationName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Owner,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] [Alias("skip_validation")]$SkipValidation,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [boolean] [Alias("read_only")]$ReadOnly,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("path")]$URL,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("credential_name")]$CredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
	)
	begin {
		$requestMethod = "PATCH"
	}	
	process {
		$apiEndpoint = "/2.1/unity-catalog/external-locations/$ExternalLocationName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$parameters | Add-Property -Name "name" -Value $NewExternalLocationName -Force
		$parameters | Add-Property -Name "url" -Value $URL -Force
		$parameters | Add-Property -Name "credential_name" -Value $CredentialName -Force
		$parameters | Add-Property -Name "owner" -Value $Owner -Force
		$parameters | Add-Property -Name "read_only" -Value $ReadOnly -Force
		$parameters | Add-Property -Name "skip_validation" -Value $SkipValidation.IsPresent -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force
		$parameters | Add-Property -Name "force" -Value $Force.IsPresent -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Remove-UnityCatalogExternalLocation {
	<#
		.SYNOPSIS
		Deletes the specified repo.
		.DESCRIPTION
		Deletes the specified repo. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/delete-repo
		.PARAMETER CatalogName 
		The ID for the corresponding repo to delete.
		.EXAMPLE
		Delete-UnityCatalogExternalLocation -CatalogName 123
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "external_location_name")]$ExternalLocationName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
	)
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.1/unity-catalog/external-locations/$ExternalLocationName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ 
			force = $Force.IsPresent
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}