Function Add-DatabricksApiToken
{
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
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [long] $LifetimeSeconds = -1, 
		[Parameter(Mandatory = $false, Position = 2)] [string] $Comment
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/token/create"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}

		$parameters | Add-Property -Name "lifetime_seconds" -Value $LifetimeSeconds -NullValue -1
		$parameters | Add-Property -Name "comment" -Value $Comment 
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}


Function Get-DatabricksApiToken
{
	<#
			.SYNOPSIS
			List all the valid tokens for a user-workspace pair.
			.DESCRIPTION
			List all the valid tokens for a user-workspace pair.
			Official API Documentation: https://docs.databricks.com/api/latest/tokens.html#list
			.EXAMPLE
			Get-DatabricksApiToken
	#>
	[CmdletBinding()]
	param ()
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/token/list"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.token_infos
	}
}


Function Remove-DatabricksApiToken
{
  <#
      .SYNOPSIS
      Revoke an access token. This call returns the error RESOURCE_DOES_NOT_EXIST if a token with the specified ID is not valid.
      .DESCRIPTION
      Revoke an access token. This call returns the error RESOURCE_DOES_NOT_EXIST if a token with the specified ID is not valid.
      Official API Documentation: https://docs.databricks.com/api/latest/tokens.html#revoke
      .PARAMETER TokenID 
      The ID of the token to be revoked.
      .EXAMPLE
      Remove-DatabricksApiToken -TokenID 1234
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("token_id")] [string] $TokenID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $tokenIDValues = (Get-DynamicParamValues { Get-DatabricksApiToken }).token_id
    New-DynamicParam -Name TokenID -ValidateSet $tokenIDValues -Alias 'token_id' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/token/delete"
    
    $TokenID = $PSBoundParameters.TokenID
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      token_id = $TokenID 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}