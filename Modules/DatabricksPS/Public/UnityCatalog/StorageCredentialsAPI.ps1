Function Get-UnityCatalogStorageCredential {
	<#
		.SYNOPSIS
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array.
		.DESCRIPTION
		Gets an array of catalogs in the metastore. If the caller is the metastore admin, all catalogs will be retrieved. Otherwise, only catalogs owned by the caller (or for which the caller has the USE_CATALOG privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array. 
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/storage-credentials/list
		Official API Documentation: https://docs.databricks.com/api-explorer/workspace/storage-credentials/get
		.PARAMETER CatalogName 
		The name of the catalog to retrieve. This field is optional and can be used as a filter on one particular catalog.
		.EXAMPLE
		Get-UnityCatalogStorageCredential -CatalogName MyCatalog
		.EXAMPLE
		#AUTOMATED_TEST:List existing Unity Catalogs
		Get-UnityCatalogStorageCredential
	#>
	param 
	(	
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("name", "storage_credential_name")] [string] $StorageCredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Raw
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.1/unity-catalog/storage-credentials"
	}	
	process {
		If($PSBoundParameters.ContainsKey("StorageCredentialName")) {
			$apiEndpoint = "/2.1/unity-catalog/storage-credentials/$StorageCredentialName"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSBoundParameters.ContainsKey("StorageCredentialName") -or $Raw.IsPresent) {
			# if a CatalogName was specified, we return the result as it is
			return $result
		}
		else {
			# if no CatalogName was specified, we return the catalogs as an array
			return $result.storage_credentials
		}
	}
}

Function Add-UnityCatalogStorageCredential {
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
		Add-UnityCatalogStorageCredential -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "storage_credential_name")]$StorageCredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] [Alias("skip_validation")]$SkipValidation,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [boolean] [Alias("read_only")]$ReadOnly,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment
	)
	DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if((Get-DatabricksCloudProvider) -eq "Azure" -or $true)
		{
			New-DynamicParam -ParameterSetName "Azure" -Name AccessConnectorID -Alias 'access_connector_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary

			New-DynamicParam -ParameterSetName "AzureSP" -Name TenantID -Alias 'tenant_id','directory_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AzureSP" -Name ClientID -Alias 'client_id','application_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AzureSP" -Name ClientSecret -Alias 'client_secret' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}
		elseif((Get-DatabricksCloudProvider) -eq "AWS")
		{
			New-DynamicParam -ParameterSetName "AWS" -Name RoleARN -Alias 'role_arn' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AWS" -Name UnityCatalogIamARN -Alias 'unity_catalog_iam_arn' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AWS" -Name ExternalID -Alias 'external_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}
		elseif((Get-DatabricksCloudProvider) -eq "GCP")
		{
			New-DynamicParam -ParameterSetName "GCP" -Name EMail -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "GCP" -Name PrivateKeyID -Alias 'private_key_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "GCP" -Name PrivateKey -Alias 'private_key' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}

		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.1/unity-catalog/storage-credentials"
	}
		
	process {    
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			name    = $StorageCredentialName
		}

		$parameters | Add-Property -Name "skip_validation" -Value $SkipValidation.IsPresent -Force
		$parameters | Add-Property -Name "read_only" -Value $ReadOnly -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force

		if($PSCmdlet.ParameterSetName -eq "Azure")
		{
			$credential = @{
				access_connector_id = $PSBoundParameters.AccessConnectorID
			}

			$parameters | Add-Property -Name "azure_managed_identity" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "AzureSP")
		{
			$credential = @{
				directory_id = $PSBoundParameters.TenantID
				application_id = $PSBoundParameters.ClientID
				client_secret = $PSBoundParameters.ClientSecret
			}

			$parameters | Add-Property -Name "azure_service_principal" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "AWS")
		{
			$credential = @{
				role_arn = $PSBoundParameters.RoleARN
				unity_catalog_iam_arn = $PSBoundParameters.UnityCatalogIamARN
				external_id = $PSBoundParameters.ExternalID
			}

			$parameters | Add-Property -Name "aws_iam_role" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "GCP")
		{
			$credential = @{
				email = $PSBoundParameters.EMail
				private_key_id = $PSBoundParameters.PrivateKeyID
				private_key = $PSBoundParameters.PrivateKey
			}

			$parameters | Add-Property -Name "gcp_service_account_key" -Value $credential -Force
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Update-UnityCatalogStorageCredential {
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
		Update-UnityCatalogStorageCredential -CatalogName 123 -Branch "main"
		.EXAMPLE
		Update-UnityCatalogStorageCredential -CatalogName 123 -Tag "v2.3.1"
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "storage_credential_name")]$StorageCredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("new_name", "new_storage_credential_name")]$NewStorageCredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Owner,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] [Alias("skip_validation")]$SkipValidation,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [boolean] [Alias("read_only")]$ReadOnly,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
	)
	DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if((Get-DatabricksCloudProvider) -eq "Azure")
		{
			New-DynamicParam -ParameterSetName "Azure" -Name AccessConnectorID -Alias 'access_connector_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary

			New-DynamicParam -ParameterSetName "AzureSP" -Name TenantID -Alias 'tenant_id','directory_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AzureSP" -Name ClientID -Alias 'client_id','application_id' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AzureSP" -Name ClientSecret -Alias 'client_secret' -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}
		elseif((Get-DatabricksCloudProvider) -eq "AWS")
		{
			New-DynamicParam -ParameterSetName "AWS" -Name RoleARN -Alias 'role_arn' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AWS" -Name UnityCatalogIamARN -Alias 'unity_catalog_iam_arn' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "AWS" -Name ExternalID -Alias 'external_id' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
		}
		elseif((Get-DatabricksCloudProvider) -eq "GCP")
		{
			New-DynamicParam -ParameterSetName "GCP" -Name EMail -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "GCP" -Name PrivateKeyID -Alias 'private_key_id' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
			New-DynamicParam -ParameterSetName "GCP" -Name PrivateKey -Alias 'private_key' -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
		}

		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
	begin {
		$requestMethod = "PATCH"
	}	
	process {
		$apiEndpoint = "/2.1/unity-catalog/storage-credentials/$StorageCredentialName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$parameters | Add-Property -Name "name" -Value $NewStorageCredentialName -Force
		$parameters | Add-Property -Name "owner" -Value $Owner -Force
		$parameters | Add-Property -Name "read_only" -Value $ReadOnly -Force
		$parameters | Add-Property -Name "skip_validation" -Value $SkipValidation.IsPresent -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force
		$parameters | Add-Property -Name "force" -Value $Force.IsPresent -Force

		if($PSCmdlet.ParameterSetName -eq "Azure")
		{
			$credential = @{
				access_connector_id = $AccessConnectorID
				credential_id = $CredentialID
			}

			$parameters | Add-Property -Name "azure_managed_identity" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "AzureSP")
		{
			$credential = @{
				directory_id = $PSBoundParameters.TenantID
				application_id = $PSBoundParameters.ClientID
				client_secret = $PSBoundParameters.ClientSecret
				credential_id = $CredentialID
			}

			$parameters | Add-Property -Name "azure_managed_identity" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "AWS")
		{
			$credential = @{
				role_arn = $PSBoundParameters.RoleARN
				unity_catalog_iam_arn = $PSBoundParameters.UnityCatalogIamARN
				external_id = $PSBoundParameters.ExternalID
			}

			$parameters | Add-Property -Name "aws_iam_role" -Value $credential -Force
		}
		elseif($PSCmdlet.ParameterSetName -eq "GCP")
		{
			$credential = @{
				email = $PSBoundParameters.EMail
				private_key_id = $PSBoundParameters.PrivateKeyID
				private_key = $PSBoundParameters.PrivateKey
			}

			$parameters | Add-Property -Name "gcp_service_account_key" -Value $credential -Force
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Remove-UnityCatalogStorageCredential {
	<#
		.SYNOPSIS
		Deletes the specified repo.
		.DESCRIPTION
		Deletes the specified repo. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/delete-repo
		.PARAMETER CatalogName 
		The ID for the corresponding repo to delete.
		.EXAMPLE
		Delete-UnityCatalogStorageCredential -CatalogName 123
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "storage_credential_name")]$StorageCredentialName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Force
	)
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.1/unity-catalog/storage-credentials/$StorageCredentialName"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ 
			force = $Force.IsPresent
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}