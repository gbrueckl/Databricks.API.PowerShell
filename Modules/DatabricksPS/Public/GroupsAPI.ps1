Function Add-DatabricksGroupMember {
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
      .PARAMETER ServicePrincipalID
      The Application-ID of the Service Principal to add to the group. E.g. from Get-DatabricksSCIMServicePrincipal
      .PARAMETER ParentGroupName 
      Name of the parent group to which the new member will be added. This field is required.
      .EXAMPLE
      Add-DatabricksGroupMember -UserName "me@mydomain.com" -ParentGroupName "Data Scientists"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ParameterSetName = "AddUser", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("user_name")] [string] $UserName,
    [Parameter(ParameterSetName = "AddServicePrincipal", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("applicationId")] [string] $ServicePrincipalID
    #[Parameter(ParameterSetName = "AddGroup", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("group_name")] [string] $GroupName, 
    #[Parameter(Mandatory = $true, Position = 2)] [string] $ParentGroupName
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = Get-DynamicParamValues { Get-DatabricksGroup }
    New-DynamicParam -Name ParentGroupName -ValidateSet $groupValues -Alias 'parent_name', 'group_name', 'displayName' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary

    New-DynamicParam -Name GroupName -ParameterSetName 'AddGroup'  -ValidateSet $groupValues  -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/groups/add-member"
  }
	
  process {    
    $ParentGroupName = $PSBoundParameters.ParentGroupName
    $GroupName = $PSBoundParameters.GroupName

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      parent_name = $ParentGroupName 
    }
			
    switch ($PSCmdlet.ParameterSetName) { 
      "AddUser" { $parameters | Add-Property -Name "user_name" -Value $UserName }
      "AddServicePrincipal" { $parameters | Add-Property -Name "user_name" -Value $ServicePrincipalID } # Service Principals are added like regular users
      "AddGroup" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    # this call does not return any results
    #return $result
  }
}

Function Add-DatabricksGroup {
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
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name", "displayName")] [string] $GroupName
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

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Get-DatabricksGroupMember {
  <#
      .SYNOPSIS
      Returns all of the members of a particular group. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
      .DESCRIPTION
      Returns all of the members of a particular group. This call returns an error RESOURCE_DOES_NOT_EXIST if a group with the given name does not exist.
      Official API Documentation: https://docs.databricks.com/api/latest/groups.html#list-members
      .PARAMETER GroupName 
      The group whose members we want to retrieve. This field is required.
      .PARAMETER LegacyOutput 
      The legacy output only shows user_name or group_name (whatever appears first). However, the returned object still contains both properties!
      The new (non-legacy) output is a hashtable showing all information/members.
      .EXAMPLE
      Get-DatabricksGroupMember -GroupName "Data Scientists"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name")] [string] $GroupName,
    [Parameter(Mandatory = $false)] [switch] $LegacyOutput
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = Get-DynamicParamValues { Get-DatabricksGroup }
    New-DynamicParam -Name GroupName -ValidateSet $groupValues -Alias 'group_name', 'displayName' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/groups/list-members"
  }
	
  process {
    $GroupName = $PSBoundParameters.GroupName

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      group_name = $GroupName 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if ($LegacyOutput) {
      return $result.members
    }
    else {
      # we need to conver the result to a hash-table as otherwise the object does not show "group_name" even though groups would exist
      return $result.members | ConvertTo-Hashtable
    }
  }
}

Function Get-DatabricksGroup {
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
    $parameters = @{ }
		
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.group_names
  }
}

Function Get-DatabricksGroupMembership {
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
      .PARAMETER ServicePrincipalID
      The Application-ID of the Service Principal to add to the group. E.g. from Get-DatabricksSCIMServicePrincipal
      .EXAMPLE
      #AUTOMATED_TEST:Get Group Membership
      $user = (Get-DatabricksSCIMUser)[0]

      Get-DatabricksGroupMembership -Username $user.emails[0].value
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ParameterSetName = "UserMemberships", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("user_name")] [string] $UserName,
    [Parameter(ParameterSetName = "ServicePrincipalMemberships", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("applicationId")] [string] $ServicePrincipalID
    
    #[Parameter(ParameterSetName = "GroupMemberships", Mandatory = $true, Position = 1)] [string] $GroupName
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = Get-DynamicParamValues { Get-DatabricksGroup }
    New-DynamicParam -Name GroupName -ParameterSetName 'GroupMemberships' -ValidateSet $groupValues -Alias 'group_name', 'displayName' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/groups/list-parents"
  }
	
  process {
    $GroupName = $PSBoundParameters.GroupName

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{ }
			
    switch ($PSCmdlet.ParameterSetName) { 
      "UserMemberships" { $parameters | Add-Property -Name "user_name" -Value $UserName }
      "ServicePrincipalMemberships" { $parameters | Add-Property -Name "user_name" -Value $ServicePrincipalID }
      "GroupMemberships" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
    }
		
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.group_names
  }
}

Function Remove-DatabricksGroupMember {
  <#
      .SYNOPSIS
      Removes a user or group from a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
      .DESCRIPTION
      Removes a user or group from a group. This call returns an error RESOURCE_DOES_NOT_EXIST if a user or group with the given name does not exist, or if a group with the given parent name does not exist.
      Official API Documentation: https://docs.databricks.com/api/latest/groups.html#remove-member
      .PARAMETER UserName 
      The name of the user to remove from the group.
      .PARAMETER GroupName 
      The name of the group to remove from the group.
      .PARAMETER ServicePrincipalID
      The Application-ID of the Service Principal to remove from the group. E.g. from Get-DatabricksSCIMServicePrincipal
      .PARAMETER ParentGroupName 
      Name of the parent group from which the user/group will be removed. This field is required.
      .EXAMPLE
      Remove-DatabricksGroupMember -UserName "me@mydomain.com" -ParentName "Data Scientists"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(ParameterSetName = "RemoveUser", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("user_name")] [string] $UserName,
    [Parameter(ParameterSetName = "RemoveServicePrincipal", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("applicationId")] [string] $ServicePrincipalID
    
    #[Parameter(ParameterSetName = "RemoveGroup", Mandatory = $true, Position = 1)] [string] $GroupName, 
    #[Parameter(Mandatory = $true, Position = 2)] [string] $ParentGroupName
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = Get-DynamicParamValues { Get-DatabricksGroup }
    New-DynamicParam -Name ParentGroupName -ValidateSet $groupValues -Alias 'parent_name', 'group_name', 'displayName' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary

    New-DynamicParam -Name GroupName -ParameterSetName 'RemoveGroup'  -ValidateSet $groupValues -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/groups/remove-member"
  }
	
  process {
    $ParentGroupName = $PSBoundParameters.ParentGroupName
    $GroupName = $PSBoundParameters.GroupName

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      parent_name = $ParentGroupName 
    }
		
    switch ($PSCmdlet.ParameterSetName) { 
      "RemoveUser" { $parameters | Add-Property -Name "user_name" -Value $UserName }
      "RemoveServicePrincipal" { $parameters | Add-Property -Name "user_name" -Value $ServicePrincipalID } # Service Principals are removed like regular users
      "RemoveGroup" { $parameters | Add-Property -Name "group_name" -Value $GroupName }
    }
		
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.group_names
  }
}

Function Remove-DatabricksGroup {
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
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [Alias("group_name")] [string] $GroupName
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = Get-DynamicParamValues { Get-DatabricksGroup }
    New-DynamicParam -Name GroupName -ValidateSet $groupValues -Alias 'group_name', 'displayName' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
    
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/groups/delete"
  }
	
  process {
    $GroupName = $PSBoundParameters.GroupName

    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      group_name = $GroupName 
    }
		
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.group_names
  }
}