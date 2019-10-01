Function Add-DatabricksInstanceProfile
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
			Add-DatabricksInstanceProfile -InstanceProfileARN "arn:aws:iam::123456789:instance-profile/datascience-role" -SkipValidation
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("instance_profile_arn")] [string] $InstanceProfileARN, 
		[Parameter(Mandatory = $false, Position = 2)] [switch] $SkipValidation
	)
	
	begin {
		$requestMethod = "POST"
		$apiEndpoint =  "/2.0/instance-profiles/add"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			instance_profile_arn = $InstanceProfileARN
		}
	
		if($SkipValidation)
		{
			$parameters | Add-Property -Name "skip_validation" -Value $true
		}
			
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Get-DatabricksInstanceProfile
{
	<#
			.SYNOPSIS
			Lists the instance profiles that the calling user can use to launch a cluster.
			.DESCRIPTION
			Lists the instance profiles that the calling user can use to launch a cluster.
			Official API Documentation: https://docs.databricks.com/api/latest/instance-profiles.html#profiles-list
			.EXAMPLE
			Get-DatabricksInstanceProfile
	#>
	[CmdletBinding()]
	param ()
	
	begin {
		$requestMethod = "GET"
		$apiEndpoint =  "/2.0/instance-profiles/list"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}
			
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.instance_profiles
	}
}

Function Remove-DatabricksInstanceProfile
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
			Remove-DatabricksInstanceProfile -InstanceProfileARN "arn:aws:iam::123456789:instance-profile/datascience-role"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("instance_profile_arn")] [string] $InstanceProfileARN
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint =  "/2.0/instance-profiles/remove"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			instance_profile_arn = $InstanceProfileARN 
		}
			
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.instance_profiles
	}
}