#requires -Version 3.0
Function Add-InstanceProfile
{
	<#
			.SYNOPSIS
			Registers an instance profile in Databricks. In the UI, you can then give users the permission to use this instance profile when launching clusters.
			.DESCRIPTION
			Registers an instance profile in Databricks. In the UI, you can then give users the permission to use this instance profile when launching clusters.
			Official API Documentation: https://docs.databricks.com/api/latest/instance-profiles.html#profiles-add
			.PARAMETER InstanceProfileARN 
			The AWS ARN of the instance profile to register with Databricks. It should look like: arn:aws:iam::<account-id>:instance-profile/<name>. This field is required.
			.PARAMETER SkipValidation 
			By default, Databricks validates that it has sufficient permissions to launch instances with the instance profile. This validation uses AWS dry-run mode for the RunInstances API. If validation fails with an error message that does not indicate an IAM related permission issue, (e.g. "Your requested instance type is not supported in your requested Availability Zone"), you may pass this flag to skip the validation and forcibly add the instance profile.
			.EXAMPLE
			Add-InstanceProfile -InstanceProfileARN "arn:aws:iam::123456789:instance-profile/datascience-role" -SkipValidation
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $InstanceProfileARN, 
		[Parameter(Mandatory = $false, Position = 2)] [switch] $SkipValidation
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/instance-profiles/add"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		instance_profile_arn = $InstanceProfileARN
	}
	
	if($SkipValidation)
	{
		$parameters | Add-Property -Name "skip_validation" -Value $true
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Get-InstanceProfile
{
	<#
			.SYNOPSIS
			Lists the instance profiles that the calling user can use to launch a cluster.
			.DESCRIPTION
			Lists the instance profiles that the calling user can use to launch a cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/instance-profiles.html#profiles-list
			.EXAMPLE
			Get-InstanceProfile
	#>
	[CmdletBinding()]
	param ()

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/instance-profiles/list"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Remove-InstanceProfile
{
	<#
			.SYNOPSIS
			Removes the instance profile with the provided ARN. Existing clusters with this instance profile will continue to function.
			.DESCRIPTION
			Removes the instance profile with the provided ARN. Existing clusters with this instance profile will continue to function.
			Official API Documentation: https://docs.databricks.com/api/latest/instance-profiles.html#profiles-remove
			.PARAMETER InstanceProfileARN 
			The arn of the instance profile to remove. This field is required.
			.EXAMPLE
			Remove-InstanceProfile -InstanceProfileARN "arn:aws:iam::123456789:instance-profile/datascience-role"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $InstanceProfileARN
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/instance-profiles/remove"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		instance_profile_arn = $InstanceProfileARN 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}