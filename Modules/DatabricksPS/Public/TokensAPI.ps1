Function Add-ApiToken
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
			Add-ApiToken -LifetimeSeconds 360 -Comment "MyComment
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [long] $LifetimeSeconds = -1, 
		[Parameter(Mandatory = $false, Position = 2)] [string] $Comment
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/token/create"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{}

	$parameters | Add-Property -Name "lifetime_seconds" -Value $LifetimeSeconds -NullValue -1
	$parameters | Add-Property -Name "comment" -Value $Comment 
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-ApiToken
{
	<#
			.SYNOPSIS
			List all the valid tokens for a user-workspace pair.
			.DESCRIPTION
			List all the valid tokens for a user-workspace pair.
			Official API Documentation: https://docs.databricks.com/api/latest/tokens.html#list
			.EXAMPLE
			Get-ApiToken -Token_Infos <token_infos>
	#>
	[CmdletBinding()]
	param ()

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/token/list"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result.token_infos
}


Function Remove-ApiToken
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
			Remove-ApiToken -TokenID 1234
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $TokenID
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/token/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		token_id = $TokenID 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}