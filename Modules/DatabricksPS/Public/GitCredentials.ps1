Function Get-DatabricksGitCredential {
  <#
      .SYNOPSIS
      Returns the calling user's Git credentials. One credential per user is supported.
      .DESCRIPTION
      Returns the calling user's Git credentials. One credential per user is supported.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/gitcredentials.html#operation/get-git-credential-list
      .EXAMPLE
      #AUTOMATED_TEST:List Git Credentials
      Get-DatabricksGitCredential
      .EXAMPLE
      Get-DatabricksGitCredential -CredentialID 1103348908666947
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("credential_id")] [string] $CredentialID
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/git-credentials"
  }
	
  process {    
    if ($CredentialID) {
      Write-Verbose "CredentialID specified ($CredentialID) - using get endpoint instead of list endpoint..."
      $apiEndpoint = "/2.0/git-credentials/$CredentialID"
    }

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{}

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if ($ClusterID)
    {
      return $result
    }
    else {
      return $result.credentials
    }
  }
}


Function Add-DatabricksGitCredential {
  <#
			.SYNOPSIS
			Creates a Git credential entry for the user. Only one Git credential per user is supported, so any attempts to create credentials if an entry already exists will fail. Use the PATCH endpoint to update existing credentials, or the DELETE endpoint to delete existing credentials.
			.DESCRIPTION
			Creates a Git credential entry for the user. Only one Git credential per user is supported, so any attempts to create credentials if an entry already exists will fail. Use the PATCH endpoint to update existing credentials, or the DELETE endpoint to delete existing credentials.
			Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/gitcredentials.html#operation/create-git-credential
			.PARAMETER GitProvider 
			Git provider. This field is case-insensitive. The available Git providers are awsCodeCommit, azureDevOpsServices, bitbucketCloud, bitbucketServer, gitHub, gitHubEnterprise, gitLab, and gitLabEnterpriseEdition.
      .PARAMETER GitUsername 
			Git username.
			.PARAMETER PersonalAccessToken 
			The personal access token used to authenticate to the corresponding Git provider.
      .EXAMPLE
			Add-DatabricksGitCredential -PersonalAccessToken "abc123" -GitUsername "myUser" -GitProvider "azureDevOpsServices"
	#>
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [ValidateSet("awsCodeCommit", "azureDevOpsServices", "azureDevOpsServicesAad", "bitbucketCloud", "bitbucketServer", "gitHub", "gitHubEnterprise", "gitLab", "gitLabEnterpriseEdition")] [Alias("git_provider", "provider")] $GitProvider
    #[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("git_username", "username")] $GitUsername, 
    #[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("personal_access_token", "pat")] $PersonalAccessToken
  )
  DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if($GitProvider -ne "azureDevOpsServicesAad") {
			New-DynamicParam -Name "GitUsername" -Alias "git_username", "username" -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
      New-DynamicParam -Name "PersonalAccessToken" -Alias "personal_access_token", "pat" -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}

		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/git-credentials"
  }
	
  process {
    $GitUsername = $PSBoundParameters.GitUsername
    $PersonalAccessToken = $PSBoundParameters.PersonalAccessToken

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      git_provider = $GitProvider
    }
    $parameters | Add-Property  -Name "git_username" -Value $GitUsername -Force
    $parameters | Add-Property  -Name "personal_access_token" -Value $PersonalAccessToken -Force
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    return $result
  }
}


Function Update-DatabricksGitCredential {
  <#
			.SYNOPSIS
			Creates a Git credential entry for the user. Only one Git credential per user is supported, so any attempts to create credentials if an entry already exists will fail. Use the PATCH endpoint to update existing credentials, or the DELETE endpoint to delete existing credentials.
			.DESCRIPTION
			Creates a Git credential entry for the user. Only one Git credential per user is supported, so any attempts to create credentials if an entry already exists will fail. Use the PATCH endpoint to update existing credentials, or the DELETE endpoint to delete existing credentials.
			Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/gitcredentials.html#operation/update-git-credential
			.PARAMETER GitProvider 
			Git provider. This field is case-insensitive. The available Git providers are awsCodeCommit, azureDevOpsServices, bitbucketCloud, bitbucketServer, gitHub, gitHubEnterprise, gitLab, and gitLabEnterpriseEdition.
      .PARAMETER GitUsername 
			Git username.
			.PARAMETER PersonalAccessToken 
			The personal access token used to authenticate to the corresponding Git provider.
      .EXAMPLE
			Update-DatabricksGitCredential -CredentialID "339753641436544" -PersonalAccessToken "abc123" -GitUsername "myUser" -GitProvider "azureDevOpsServices"
	#>
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("credential_id")] [string] $CredentialID,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [ValidateSet("awsCodeCommit", "azureDevOpsServices", "azureDevOpsServicesAad", "bitbucketCloud", "bitbucketServer", "gitHub", "gitHubEnterprise", "gitLab", "gitLabEnterpriseEdition")] [Alias("git_provider", "provider")] $GitProvider
    #[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("git_username", "username")] $GitUsername, 
    #[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("personal_access_token", "pat")] $PersonalAccessToken
  )
  DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if($GitProvider -ne "azureDevOpsServicesAad") {
			New-DynamicParam -Name "GitUsername" -Alias "git_username", "username" -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
      New-DynamicParam -Name "PersonalAccessToken" -Alias "personal_access_token", "pat" -ValueFromPipelineByPropertyName -Mandatory -DPDictionary $Dictionary
		}

		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
  begin {
    $requestMethod = "PATCH"
    $apiEndpoint = "/2.0/git-credentials/$CredentialID"
  }
	
  process {
    $GitUsername = $PSBoundParameters.GitUsername
    $PersonalAccessToken = $PSBoundParameters.PersonalAccessToken

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      personal_access_token = $PersonalAccessToken 
    }
    $parameters | Add-Property -Name "git_username" -Value $GitUsername -Force
    $parameters | Add-Property -Name "git_provider" -Value $GitProvider -Force
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    return $result
  }
}


Function Remove-DatabricksGitCredential {
  <#
      .SYNOPSIS
      Deletes the specified credential.
      .DESCRIPTION
      Deletes the specified credential.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/gitcredentials.html#operation/delete-git-credential
      .PARAMETER CredentialID 
      The ID for the corresponding credential to delete.
      .EXAMPLE
      Remove-DatabricksGitCredential -CredentialID "93488329053511"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("credential_id")] [string] $CredentialID
  )
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/git-credentials/$CredentialID"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{}
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}