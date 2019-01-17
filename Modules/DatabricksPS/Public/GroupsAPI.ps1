Function Add-GroupMember
{
	<#
			.SYNOPSIS
			Adds a user or group to a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
			.DESCRIPTION
			Adds a user or group to a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#add-member
			.PARAMETER UserName 
			The name of the user to add to the group.
			.PARAMETER GroupName 
			The name of the group to add to the group.
			.PARAMETER ParentGroupName 
			Name of the parent group to which the new member will be added. This field is required.
			.EXAMPLE
			Add-DatabricksGroupMember -UserName "me@mydomain.com" -ParentGroupName "Data Scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "AddUser", Mandatory = $true, Position = 1)] [string] $UserName,
		[Parameter(ParameterSetName = "AddGroup", Mandatory = $true, Position = 1)] [string] $GroupName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $ParentGroupName
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/groups/add-member"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			parent_name = $ParentGroupName 
		}
			
		switch ($PSCmdlet.ParameterSetName) 
		{ 
			"AddUser"  { $parameters | Add-Property -Name "user_name" -Value $UserName }
			"AddGroup" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
		}

		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Add-Group
{
	<#
			.SYNOPSIS
			Creates a new group with the given name. This call returns an error RESOURCE_ALREADY_EXISTS if a group with the given name already exists.
			.DESCRIPTION
			Creates a new group with the given name. This call returns an error RESOURCE_ALREADY_EXISTS if a group with the given name already exists.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#create
			.PARAMETER GroupName 
			Name for the group; must be unique among groups owned by this organization. This field is required.
			.EXAMPLE
			Add-DatabricksGroup -GroupName "Data Scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name")] [string] $GroupName
	)
	
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/groups/create"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			group_name = $GroupName 
		}

		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}

Function Get-GroupMember
{
	<#
			.SYNOPSIS
			Returns all of the members of a particular group. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
			.DESCRIPTION
			Returns all of the members of a particular group. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#list-members
			.PARAMETER GroupName 
			The group whose members we want to retrieve. This field is required.
			.EXAMPLE
			Get-DatabricksGroupMember -GroupName "Data Scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name")] [string] $GroupName
	)
	
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/groups/list-members"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			group_name = $GroupName 
		}

		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
		return $result.members
	}
}

Function Get-Group
{
	<#
			.SYNOPSIS
			Returns all of the groups in an organization.
			.DESCRIPTION
			Returns all of the groups in an organization.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#list
			.EXAMPLE
			Get-DatabricksGroup
	#>
	[CmdletBinding()]
	param ()
	
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/groups/list"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}
		
		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.group_names
	}
}

Function Get-Membership
{
	<#
			.SYNOPSIS
			Retrieves all groups in which a given user or group is a member (note: this method is non-recursive - it will return all groups in which the given user or group is a member but not the groups in which those groups are members). This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist.
			.DESCRIPTION
			Retrieves all groups in which a given user or group is a member (note: this method is non-recursive - it will return all groups in which the given user or group is a member but not the groups in which those groups are members). This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#list-parents
			.PARAMETER UserName 
			The name of the user to add to the group.
			.PARAMETER GroupName 
			The name of the group to add to the group.
			.EXAMPLE
			Get-DatabricksMembership GroupName "Data Scientists
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "UserMemberships", Mandatory = $true, Position = 1)] [string] $UserName,
		[Parameter(ParameterSetName = "GroupMemberships", Mandatory = $true, Position = 1)] [string] $GroupName
	)
	
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/groups/list-parents"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}
			
		switch ($PSCmdlet.ParameterSetName) 
		{ 
			"UserMemberships"  { $parameters | Add-Property -Name "user_name" -Value $UserName }
			"GroupMemberships" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
		}
		
		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.group_names
	}
}

Function Remove-GroupMember
{
	<#
			.SYNOPSIS
			Removes a user or group from a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
			.DESCRIPTION
			Removes a user or group from a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#remove-member
			.PARAMETER UserName 
			The name of the user to remove to the group.
			.PARAMETER GroupName 
			The name of the group to remove to the group.
			.PARAMETER ParentGroupName 
			Name of the parent group from which the user/group will be removed. This field is required.
			.EXAMPLE
			Remove-DatabricksGroupMember -UserName "me@mydomain.com" -ParentName "Data Scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "RemoveUser", Mandatory = $true, Position = 1)] [string] $UserName,
		[Parameter(ParameterSetName = "RemoveGroup", Mandatory = $true, Position = 1)] [string] $GroupName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $ParentGroupName
	)
	
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/groups/remove-member"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			parent_name = $ParentGroupName 
		}
		
		switch ($PSCmdlet.ParameterSetName) 
		{ 
			"RemoveUser"  { $parameters | Add-Property -Name "user_name" -Value $UserName }
			"RemoveGroup" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
		}
		
		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.group_names
	}
}

Function Remove-Group
{
	<#
			.SYNOPSIS
			Removes a group from this organization. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
			.DESCRIPTION
			Removes a group from this organization. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
			Official API Documentation: https://docs.databricks.com/api/latest/groups.html#delete
			.PARAMETER GroupName 
			The group to remove. This field is required.
			.EXAMPLE
			Remove-DatabricksGroup -GroupName "Data Scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name")] [string] $GroupName
	)
	
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/groups/delete"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			group_name = $GroupName 
		}
		
		$result = Invoke-ApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.group_names
	}
}