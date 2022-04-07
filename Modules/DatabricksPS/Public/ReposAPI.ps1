Function Get-DatabricksRepo {
	<#
		.SYNOPSIS
		Lists all repos or returns a specific repo for a given RepoID.
		.DESCRIPTION
		Lists all repos or returns a specific repo for a given RepoID. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/get-repos
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/get-repo
		.PARAMETER RepoID 
		The canonical identifier of the repo to retrieve. This field is optional and can be used as a filter on one particular repo id.
		.PARAMETER PathPrefix
		Filters repos that have paths starting with the given path prefix.
		.PARAMETER NextPageToken
		Token used to get the next page of results. If not specified, returns the first page of results as well as a next page token if there are more results.
		.PARAMETER Raw
		Can be used to retrieve the raw output of the API call including the next_page_token to retrieve additional pages
		.OUTPUT
		List of PSObjects with the following properties
		- repo_id
		- url
		- provider
		- path
		- branch
		- head_commit_id
		.EXAMPLE
		Get-Databricksrepo -RepoID 123
		.EXAMPLE
		#AUTOMATED_TEST:List existing Repos
		Get-DatabricksRepo
	#>
	[CmdletBinding(DefaultParametersetname = "List Repos")]
	param 
	(	
		[Parameter(ParameterSetName = "By RepoID", Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("repo_id", "id")] [int64] $RepoID,
		[Parameter(ParameterSetName = "List Repos", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("path_prefix")] [string] $PathPrefix,
		[Parameter(ParameterSetName = "List Repos", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("next_page_token")] [string] $NextPageToken,
		[Parameter(ParameterSetName = "List Repos", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Raw
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/repos"
	}
	
	process {
		if ($PSCmdlet.ParameterSetName -eq "By RepoID") {
			Write-Verbose "repoID specified ($repoID)- using Get-API instead of List-API..."
			$apiEndpoint = "/2.0/repos/$RepoID"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		if ($PSCmdlet.ParameterSetName -eq "List Repos") {
			$parameters | Add-Property  -Name "path_prefix" -Value $PathPrefix
			$parameters | Add-Property  -Name "next_page_token" -Value $NextPageToken
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSCmdlet.ParameterSetName -eq "By RepoID") {
			# if a RepoID was specified, we return the result as it is
			return $result
		}
		else {
			if ($Raw) {
				return $result
			}
			if ($result.next_page_token) {
				Write-Warning "A next_page_token was found indicating additional repos are available. Please use -Raw to to retrieve it!"
			}
			# if no RepoID was specified, we return the repos as an array
			return $result.repos
		}
	}
}

Function Add-DatabricksRepo {
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
		Add-DatabricksRepo -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $URL,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [ValidateSet("gitHub", "bitbucketCloud", "gitLab", "azureDevOpsServices", "gitHubEnterprise", "bitbucketServer", "gitLabEnterpriseEdition")] $Provider,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $Path
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/repos"
	}
		
	process {    
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			url      = $URL
			provider = $Provider
			path     = $Path
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Update-DatabricksRepo {
	<#
		.SYNOPSIS
		Updates the repo to the given branch or tag.
		.DESCRIPTION
		Updates the repo to the given branch or tag. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/update-repo
		.PARAMETER RepoID 
		The ID for the corresponding repo to access.
		.PARAMETER Branch
		Branch that the local version of the repo is checked out to.
		.PARAMETER Tag
		Tag that the local version of the repo is checked out to. Updating the repo to a tag puts the repo in a detached HEAD state. Before committing new changes, you must update the repo to a branch instead of the detached HEAD.
		.EXAMPLE
		Update-Databricksrepo -RepoID 123 -Branch "main"
		.EXAMPLE
		Update-Databricksrepo -RepoID 123 -Tag "v2.3.1"
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("repo_id", "id")] [int64] $RepoID,
		[Parameter(ParameterSetName = "Branch", Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $Branch,
		[Parameter(ParameterSetName = "Tag", Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $Tag
	)
	begin {
		$requestMethod = "PATCH"
	}
	
	process {
		$apiEndpoint = "/2.0/repos/$RepoID"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		if ($PSCmdlet.ParameterSetName -eq "Branch") {
			$parameters | Add-Property  -Name "branch" -Value $Branch
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Tag") {
			$parameters | Add-Property  -Name "tag" -Value $Tag
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Remove-DatabricksRepo {
	<#
		.SYNOPSIS
		Deletes the specified repo.
		.DESCRIPTION
		Deletes the specified repo. 
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/repos.html#operation/delete-repo
		.PARAMETER RepoID 
		The ID for the corresponding repo to delete.
		.EXAMPLE
		Delete-Databricksrepo -RepoID 123
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("repo_id", "id")] [int64] $RepoID
	)
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.0/repos/$RepoID"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}