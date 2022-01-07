Function Add-DatabricksApiToken {
	<#
			.SYNOPSIS
			Create and return a token. This call returns the error QUOTA_EXCEEDED if the caller exceeds the token quota, which is 600.
			.DESCRIPTION
			Create and return a token. This call returns the error QUOTA_EXCEEDED if the caller exceeds the token quota, which is 600.
			Official API Documentation: https://docs.databricks.com/api/latest/tokens.html#create
			.PARAMETER LifetimeSeconds 
			The lifetime of the token, in seconds. If no lifetime is specified, the token remains valid indefinitely.
			.PARAMETER Comment 
			Optional description to attach to the token.
			.EXAMPLE
			Add-DatabricksApiToken -LifetimeSeconds 360 -Comment "MyComment
	#>
	[CmdletBinding(DefaultParametersetname = "User")]
	param (
		[Parameter(ParameterSetName = "User", Mandatory = $false, Position = 1)] [long] $LifetimeSeconds = -1, 
		[Parameter(ParameterSetName = "User", Mandatory = $false, Position = 2)] [string] $Comment
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/token/create"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{ }

		$parameters | Add-Property -Name "lifetime_seconds" -Value $LifetimeSeconds -NullValue -1
		$parameters | Add-Property -Name "comment" -Value $Comment 
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}


Function Get-DatabricksApiToken {
	<#
			.SYNOPSIS
			List all the valid tokens for a user-workspace pair (User-mode).
			List all tokens belonging to a workspace or a user (Admin-mode).
			.DESCRIPTION
			List all the valid tokens for a user-workspace pair (User-mode).
			List all tokens belonging to a workspace or a user (Admin-mode).
			Official API Documentation (User-mode): https://docs.databricks.com/api/latest/tokens.html#list
			Official API Documentation (Admin-mode): https://docs.databricks.com/dev-tools/api/latest/token-management.html#operation/get-tokens
			.PARAMETER User 
			Optional, has no effect. Is only used to disinguish between User-mode (mode) and Admin-mode in the background.
			.PARAMETER Admin
			Switch to enter Admin-mode and use the TokenManagementAPI over the TokenAPI. 
			.PARAMETER TokenID
			(Admin-Mode) Used to return a single token specified by the TokenID
			.PARAMETER CreatedByUserID
			(Admin-Mode) Return all tokens created by the provided UserID
			.PARAMETER CreatedByUsername
			(Admin-Mode) Return all tokens created by the provided UserName
			.EXAMPLE
			Get-DatabricksApiToken
			.EXAMPLE
			Get-DatabricksApiToken -Admin
			.EXAMPLE
			Get-DatabricksApiToken -Admin CreatedByUserID 12345634950965130
	#>
	[CmdletBinding(DefaultParametersetname = "User")]
	param (
		[Parameter(ParameterSetName = "User", Mandatory = $false)] [switch] $User,

		[Parameter(ParameterSetName = "Admin", Mandatory = $true)]
		[Parameter(ParameterSetName = "Admin by TokenID", Mandatory = $true)]
		[Parameter(ParameterSetName = "Admin by UserID", Mandatory = $true)]
		[Parameter(ParameterSetName = "Admin by Username", Mandatory = $true)] [switch] $Admin,

		[Parameter(ParameterSetName = "Admin by TokenID", Mandatory = $true)] [Alias("token_id", "id")] [string] $TokenID,
		[Parameter(ParameterSetName = "Admin by UserID", Mandatory = $true)] [Alias("created_by_id", "created_by_user_id")] [string] $CreatedByUserID,
		[Parameter(ParameterSetName = "Admin by Username", Mandatory = $true)] [Alias("created_by_username")] [string] $CreatedByUsername
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/token/list"
	}
	
	process {
		if ($PSCmdlet.ParameterSetName.StartsWith("Admin")) {
			$apiEndpoint = "/2.0/token-management/tokens"

			if ($PSBoundParameters.ContainsKey('TokenID')) {
				$apiEndpoint += "/$TokenID"
			}
		}
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{ }

		$parameters | Add-Property -Name "created_by_id" -Value $CreatedByUserID -Force
		$parameters | Add-Property -Name "created_by_username" -Value $CreatedByUsername -Force
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSCmdlet.ParameterSetName -eq ("Admin by TokenID")) {
			return $result.token_info
		}
		else {
			return $result.token_infos
		}
	}
}


Function Remove-DatabricksApiToken {
	<#
		.SYNOPSIS
		Revoke an access token. This call returns the error RESOURCE_DOES_NOT_EXIST if a token with the specified ID is not valid.
		Delete a token, specified by its ID.
		.DESCRIPTION
		Revoke an access token. This call returns the error RESOURCE_DOES_NOT_EXIST if a token with the specified ID is not valid.
		Official API Documentation (User-mode): https://docs.databricks.com/api/latest/tokens.html#revoke
		Official API Documentation (Admin-mode): https://docs.databricks.com/dev-tools/api/latest/token-management.html#operation/delete-token
		.PARAMETER User 
		Optional, has no effect. Is only used to disinguish between User-mode (mode) and Admin-mode in the background.
		.PARAMETER Admin
		Switch to enter Admin-mode and use the TokenManagementAPI over the TokenAPI. 
		.PARAMETER TokenID 
		The ID of the token to be revoked.
		.EXAMPLE
		Remove-DatabricksApiToken -TokenID 1234
		.EXAMPLE
		Remove-DatabricksApiToken -Admin -TokenID 1234
	#>
	[CmdletBinding(DefaultParametersetname = "User")]
	param (
		[Parameter(ParameterSetName = "User", Mandatory = $false)] [switch] $User,
		[Parameter(ParameterSetName = "Admin", Mandatory = $true)] [switch] $Admin
		
		#[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("token_id")] [string] $TokenID
	)
	DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		if ($PSCmdlet.ParameterSetName -eq ("Admin")) {
			$tokenIDValues = (Get-DynamicParamValues { Get-DatabricksApiToken -Admin }).token_id
		}
		else {
			$tokenIDValues = (Get-DynamicParamValues { Get-DatabricksApiToken }).token_id
		}
		
		New-DynamicParam -Name TokenID -ValidateSet $tokenIDValues -Alias 'token_id' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/token/delete"
	}

	process {
		$TokenID = $PSBoundParameters.TokenID

		if ($PSCmdlet.ParameterSetName -eq "Admin") {
			$requestMethod = "DELETE"
			$apiEndpoint = "/2.0/token-management/tokens/$TokenID"
		}

		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}

		if ($PSCmdlet.ParameterSetName -eq "User") {
			$parameters | Add-Property -Name "token_id" -Value $TokenID -Force
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		# this API call returns no result
		# return $result
	}
}