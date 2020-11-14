Function Get-DatabricksSCIMUser {
  <#
      .SYNOPSIS
      Admin users: Retrieve a list of all users in the Databricks workspace.
      Non-admin users: Retrieve a list of all users in the Databricks workspace, returning user display name and object ID only.
      .DESCRIPTION
      Admin users: Retrieve a list of all users in the Databricks workspace.
      Non-admin users: Retrieve a list of all users in the Databricks workspace, returning user display name and object ID only.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#get-users
      .PARAMETER Format
      List -> returns a list of SCIM objects
      Raw -> return raw results
      .PARAMETER Filter
      Allows you to specify filters for the returned users. Details can be found here https://docs.databricks.com/dev-tools/api/latest/scim.html#scim-filters
      .PARAMETER UserID
      Return a specific user based on the ID
      .EXAMPLE
      Get-DatabricksSCIMUser
      .EXAMPLE
      Get-DatabricksSCIMUser -Filter 'displayName co John'
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] [ValidateSet('List', 'Raw')] $Format = 'List',
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] $Filter,
    [Parameter(ParameterSetName = 'ByUserID', Mandatory = $True)] [string] $UserID
  )
	
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/preview/scim/v2/Users"
    
    if ($PSCmdlet.ParameterSetName -eq "ByUserID") { 
      $apiEndpoint = "/2.0/preview/scim/v2/Users/$UserID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }

    if ($PSCmdlet.ParameterSetName -eq 'List') {
      $parameters | Add-Property -Name "filter" -Value $Filter -Force
    }
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -Accept 'application/scim+json'

    if ($PSCmdlet.ParameterSetName -eq "List" -and $Format -eq "List") { 
      return $result.Resources 
    }
    
    return $result
  }
}

Function Add-DatabricksSCIMUser {
  <#
      .SYNOPSIS
      Admin users: Create a user in the Databricks workspace.
      .DESCRIPTION
      Admin users: Create a user in the Databricks workspace.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#create-user
      .PARAMETER UserName
      The username of the user to add. Usually an email address.
      .PARAMETER GroupNames
      A list of existing Databricks group names to which the SP is added
      .PARAMETER GroupIDs
      A list of existing Databricks group IDs to which the SP is added
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Add-DatabricksSCIMUser -UserName John.doe@test.com -GroupNames admins -Entitlements allow-cluster-create -Verbose
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("user_name")] [string] $UserName,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $false)]
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $false)]
    [Parameter(ParameterSetName = "Entitlements", Mandatory = $true)]
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')][string[]] $Entitlements,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $true)] [Alias("group_name")] [string[]] $GroupNames,
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $true)] [Alias("group_id")] [string[]] $GroupIDs
  ) 
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/preview/scim/v2/Users"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    if ($PSCmdlet.ParameterSetName -eq "GroupNames") {
      $GroupIDs = @(Get-DatabricksSCIMGroup | Where-Object { $_.displayName -in $GroupNames }).id 
    }
    
    $groups = @($GroupIDs | ForEach-Object { @{value = $_ } })
    $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:User") -Force
    $parameters | Add-Property -Name "userName" -Value $UserName -Force
    if($PSCmdlet.ParameterSetName -ne "Entitlements")
    {
      $parameters | Add-Property -Name "groups" -Value $groups -Force
    }
    if ($Entitlements.Count -gt 0) 
    { 
      $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force 
    }
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Remove-DatabricksSCIMUser {
  <#
      .SYNOPSIS
      Admin users: Inactivate a user resource. A user that does not own or belong to a workspace in Databricks is automatically purged after 30 days.
      .DESCRIPTION
      Admin users: Inactivate a user resource. A user that does not own or belong to a workspace in Databricks is automatically purged after 30 days.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#delete-user-by-id
      .PARAMETER UserID
      The ID of the user to remove
      .EXAMPLE
      Remove-DatabricksSCIMUser -UserID 123456
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true)] [Alias("user_id")] [string] $UserID
  ) 
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/preview/scim/v2/Users/$UserID"
  }
	
  process {
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Update-DatabricksSCIMUser {
  <#
      .SYNOPSIS
      Admin users: Overwrite the user resource across multiple attributes, except those that are immutable (userName and userId).
      .DESCRIPTION
      Admin users: Overwrite the user resource across multiple attributes, except those that are immutable (userName and userId).
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim/scim-users.html#update-user-by-id-put
      .PARAMETER UserID
      The id of the user you want to update.
      .PARAMETER UserName
      The name of the user that should be updated. The username of an existing user cannot be changed!
      .PARAMETER GroupNames
      A list of existing Databricks group names to which the User is added
      .PARAMETER GroupIDs
      A list of existing Databricks group IDs to which the User is added
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Update-DatabricksSCIMUser -UserID 12345678 -UserName John.doe@test.com -GroupNames admins -Entitlements allow-cluster-create -Verbose
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("user_id")] [long] $UserID,
    [Parameter(Mandatory = $True)] [Alias("user_name")] [string] $UserName,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $false)]
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $false)]
    [Parameter(ParameterSetName = "Entitlements", Mandatory = $true)]
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')][string[]] $Entitlements,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $true)] [Alias("group_name")] [string[]] $GroupNames,
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $true)] [Alias("group_id")] [string[]] $GroupIDs
  )  
  begin {
    $requestMethod = "PUT"
    $apiEndpoint = "/2.0/preview/scim/v2/Users/$UserID"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    if ($PSCmdlet.ParameterSetName -eq "GroupNames") {
      $GroupIDs = @(Get-DatabricksSCIMGroup | Where-Object { $_.displayName -in $GroupNames }).id 
    }
    
    if($GroupIDs)
    {
      $groups = @($GroupIDs | ForEach-Object { @{value = $_ } })
    }
    if($Entitlements)
    {
      $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    }

    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:User") -Force
    $parameters | Add-Property -Name "userName" -Value $UserName -Force
    $parameters | Add-Property -Name "groups" -Value $groups -Force
    $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force 
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Get-DatabricksSCIMGroup {
  <#
      .SYNOPSIS
      Admin users: Retrieve a list of all groups in the Databricks workspace. 
      Non-admin users: Retrieve a list of all groups in the Databricks workspace, returning group display name and object ID only.
      .DESCRIPTION
      Admin users: Retrieve a list of all groups in the Databricks workspace. 
      Non-admin users: Retrieve a list of all groups in the Databricks workspace, returning group display name and object ID only.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#get-groups
      .PARAMETER Format
      List -> returns a list of SCIM objects
      Raw -> return raw results
      .PARAMETER Filter
      Allows you to specify filters for the returned users. Details can be found here https://docs.databricks.com/dev-tools/api/latest/scim.html#scim-filters
      .PARAMETER GroupID
      Return a specific user Group on the ID
      .EXAMPLE
      Get-DatabricksSCIMGroup
      .EXAMPLE
      Get-DatabricksSCIMGroup -Filter 'displayName co admin'
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] [ValidateSet('List', 'Raw')] $Format = 'List',
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] $Filter,
    [Parameter(ParameterSetName = 'ByGroupID', Mandatory = $True)] [string] $GroupID
  )
	
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/preview/scim/v2/Groups"
    
    if ($PSCmdlet.ParameterSetName -eq "ByGroupID") { 
      $apiEndpoint = "/2.0/preview/scim/v2/Groups/$GroupID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }

    if ($PSCmdlet.ParameterSetName -eq 'List') {
      $parameters | Add-Property -Name "filter" -Value $Filter -Force
    }
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -Accept 'application/scim+json'

    if ($PSCmdlet.ParameterSetName -eq "List" -and $Format -eq "List") { 
      return $result.Resources 
    }
    
    return $result
  }
}

Function Add-DatabricksSCIMGroup {
  <#
      .SYNOPSIS
      Admin users: Create a group in Databricks.
      .DESCRIPTION
      Admin users: Create a group in Databricks.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#create-group
      .PARAMETER GroupName
      The name of the group to add.
      .PARAMETER Members
      An optional list of existing Databricks user IDs to be added to the group
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Add-DatabricksSCIMGroup -GroupName 'Data Scientists'
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("group_name")] [string] $GroupName,
    [Parameter(Mandatory = $False)] [string[]] $MemberUserIDs,
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')] [string[]] $Entitlements
  )
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/preview/scim/v2/Groups"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    if($MemberUserIDs)
    {
      $groupMembers = @($MemberUserIDs | ForEach-Object { @{value = $_ } })
    }

    if($Entitlements) {
      $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    }

    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:Group") -Force
    $parameters | Add-Property -Name "displayName" -Value $GroupName -Force
    $parameters | Add-Property -Name "members" -Value $groupMembers -Force
    $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'

    return $result
  }
}

Function Remove-DatabricksSCIMGroup {
  <#
      .SYNOPSIS
      Admin users: Remove a group from Databricks. Users in the group are not removed.
      .DESCRIPTION
      Admin users: Remove a group from Databricks. Users in the group are not removed.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#delete-group-by-id
      .PARAMETER UserID
      The ID of the GroupID to remove
      .EXAMPLE
      Remove-DatabricksSCIMGroup -GroupID 123456
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("group_id")] [string] $GroupID
  ) 
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/preview/scim/v2/Groups/$GroupID"
  }
	
  process {
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Update-DatabricksSCIMGroup {
  <#
      .SYNOPSIS
      Admin users: Update a group in Azure Databricks by adding or removing members. Can add and remove individual members or groups within the group.
      .DESCRIPTION
      Admin users: Update a group in Azure Databricks by adding or removing members. Can add and remove individual members or groups within the group.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim/scim-groups.html#update-group
      .PARAMETER GroupID
      The id of the group you want to update
      .PARAMETER AddIDs
      A list of existing Databricks user or group IDs which you want to add to the groups members
      .PARAMETER RemoveIDs
      A list of existing Databricks user or group IDs which you want to remove from the groups members
      .EXAMPLE
      Update-DatabricksSCIMGroup -GroupID 123456 -AddIDs 456789 -RemoveIDs 987654
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("group_id")] [long] $GroupID,
    [Parameter(Mandatory = $false)] [long[]] $AddIDs,
    [Parameter(Mandatory = $false)][long[]] $RemoveIDs
  )  
  begin {
    $requestMethod = "PATCH"
    $apiEndpoint = "/2.0/preview/scim/v2/Groups/$GroupID"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:api:messages:2.0:PatchOp") -Force

    $operations = @()

    if($AddIDs)
    {
      $AddIDs | ForEach-Object { $operations += @{"op" = "add"; "value" = @{"members" = @(@{"value" = $_.ToString() })}} }
    }
    if($RemoveIDs)
    {
      $RemoveIDs | ForEach-Object { $operations += @{"op" = "remove"; "path" = 'members[value eq "' + $_.ToString() + '"]'} }
    }

    $parameters | Add-Property -Name "Operations" -Value $operations -Force
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Get-DatabricksSCIMServicePrincipal {
  <#
      .SYNOPSIS
      Admin users: Retrieve a list of all service principals in the Databricks workspace.
      Non-admin users: Retrieve a list of all service principals in the Databricks workspace, returning display name and object ID only.
      .DESCRIPTION
      Admin users: Retrieve a list of all service principals in the Databricks workspace.
      Non-admin users: Retrieve a list of all service principals in the Databricks workspace, returning display name and object ID only.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#get-serviceprincipals
      .PARAMETER Format
      List -> returns a list of SCIM objects
      Raw -> return raw results
      .PARAMETER Filter
      Allows you to specify filters for the returned service principals. Details can be found here https://docs.databricks.com/dev-tools/api/latest/scim.html#scim-filters
      .PARAMETER ServicePrincipalID
      Return a specific service principal based on the provided ID
      .EXAMPLE
      Get-DatabricksSCIMServicePrincipal
      .EXAMPLE
      Get-DatabricksSCIMServicePrincipal -Filter 'displayName co John'
  #>
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] [ValidateSet('List', 'Raw')] $Format = 'List',
    [Parameter(ParameterSetName = 'List', Mandatory = $False)] [string] $Filter,
    [Parameter(ParameterSetName = 'ByServicePrincipalID', Mandatory = $True)] [string] $ServicePrincipalID
  )
	
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "2.0/preview/scim/v2/ServicePrincipals"
    
    if ($PSCmdlet.ParameterSetName -eq "ByServicePrincipalID") { 
      $apiEndpoint = "2.0/preview/scim/v2/ServicePrincipals/$ServicePrincipalID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }

    if ($PSCmdlet.ParameterSetName -eq 'List') {
      $parameters | Add-Property -Name "filter" -Value $Filter -Force
    }
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -Accept 'application/scim+json'

    if ($PSCmdlet.ParameterSetName -eq "List" -and $Format -eq "List") { 
      return $result.Resources 
    }
    
    return $result
  }
}

Function Add-DatabricksSCIMServicePrincipal {
  <#
      .SYNOPSIS
      Admin users: Create a service principal in the Databricks workspace.
      .DESCRIPTION
      Admin users: Create a service principal in the Databricks workspace.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#create-serviceprincipal
      .PARAMETER ApplicationID
      The application/client ID of the service principal to add. Usually a GUID.
      .PARAMETER DisplayName
      A user-friendly name that should be shown in the UI.
      .PARAMETER GroupNames
      A list of existing Databricks group names to which the SP is added
      .PARAMETER GroupIDs
      A list of existing Databricks group IDs to which the SP is added
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Add-DatabricksSCIMServicePrincipal -ApplicationID b4647a57-063a-43e3-a6b4-c9a4e9f9f0b7 -DisplayName "my Service Principal" -GroupNames admins -Entitlements allow-cluster-create -Verbose
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("application_id", "client_id")] [string] $ApplicationID,
    [Parameter(Mandatory = $False)] [Alias("display_name")] [string] $DisplayName,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $false)]
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $false)]
    [Parameter(ParameterSetName = "Entitlements", Mandatory = $true)]
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')][string[]] $Entitlements,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $true)] [Alias("group_name")] [string[]] $GroupNames,
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $true)] [Alias("group_id")] [string[]] $GroupIDs
  )
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "2.0/preview/scim/v2/ServicePrincipals"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    if ($PSCmdlet.ParameterSetName -eq "GroupNames") {
      $GroupIDs = @(Get-DatabricksSCIMGroup | Where-Object { $_.displayName -in $GroupNames }).id 
    }
    
    if($GroupIDs)
    {
      $groups = @($GroupIDs | ForEach-Object { @{value = $_ } })
    }
    if($Entitlements)
    {
      $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    }
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal") -Force
    $parameters | Add-Property -Name "applicationId" -Value $ApplicationID -Force
    $parameters | Add-Property -Name "displayName" -Value $DisplayName -Force
    $parameters | Add-Property -Name "groups" -Value $groups -Force
    $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Remove-DatabricksSCIMServicePrincipal {
  <#
      .SYNOPSIS
      Admin users: Inactivate a service principal resource. A service principal that does not own or belong to a workspace in Databricks is automatically purged after 30 days.
      .DESCRIPTION
      Admin users: Inactivate a service principal resource. A service principal that does not own or belong to a workspace in Databricks is automatically purged after 30 days.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#delete-serviceprincipal-by-id
      .PARAMETER ServicePrincipalID
      Databricks internal ID of the service principal to remove.
      .EXAMPLE
      Remove-DatabricksSCIMServicePrincipal -ServicePrincipalID 123456
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias('service_principal_id', 'id')] [string] $ServicePrincipalID
  )
  
  begin {
    $requestMethod = "DELETE"

    $apiEndpoint = "/2.0/preview/scim/v2/ServicePrincipals/$ServicePrincipalID"
  }
	
  process {
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Update-DatabricksSCIMServicePrincipal {
  <#
      .SYNOPSIS
      Admin users: Update a service principal in the Databricks workspace. Can add/remove groups or entitlements.
      .DESCRIPTION
      Admin users: Update a service principal in the Databricks workspace. Can add/remove groups or entitlements.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#update-serviceprincipal
      .PARAMETER ServicePrincipalID
      Databricks internal ID of the service principal to update.
      .PARAMETER ApplicationID
      The application/client ID of the service principal to update. Usually a GUID.
      .PARAMETER DisplayName
      A user-friendly name that should be shown in the UI.
      .PARAMETER GroupNames
      A list of existing Databricks group names to which the SP is added
      .PARAMETER GroupIDs
      A list of existing Databricks group IDs to which the SP is added
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Update-DatabricksSCIMServicePrincipal -ServicePrincipalID b4647a57-063a-43e3-a6b4-c9a4e9f9f0b7 -ApplicationID b4647a57-063a-43e3-a6b4-c9a4e9f9f0b7 -GroupNames admins -Entitlements allow-cluster-create -Verbose
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("service_principal_id")] [long] $ServicePrincipalID,
    [Parameter(Mandatory = $True)] [Alias("application_id", "client_id")] [string] $ApplicationID,
    [Parameter(Mandatory = $True)] [Alias("display_name")] [string] $DisplayName,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $false)]
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $false)]
    [Parameter(ParameterSetName = "Entitlements", Mandatory = $true)]
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')][string[]] $Entitlements,
    [Parameter(ParameterSetName = "GroupNames", Mandatory = $true)] [Alias("group_name")] [string[]] $GroupNames,
    [Parameter(ParameterSetName = "GroupIDs", Mandatory = $true)] [Alias("group_id")] [string[]] $GroupIDs
  )  
  begin {
    $requestMethod = "PUT"
    $apiEndpoint = "/2.0/preview/scim/v2/ServicePrincipals/$ServicePrincipalID"
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }
    
    if ($PSCmdlet.ParameterSetName -eq "GroupNames") {
      $GroupIDs = @(Get-DatabricksSCIMGroup | Where-Object { $_.displayName -in $GroupNames }).id 
    }
    
    if($GroupIDs)
    {
      $groups = @($GroupIDs | ForEach-Object { @{value = $_ } })
    }
    if($Entitlements)
    {
      $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    }
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:ServicePrincipal") -Force
    $parameters | Add-Property -Name "applicationId" -Value $ApplicationID -Force
    $parameters | Add-Property -Name "displayName" -Value $DisplayName -Force
    $parameters | Add-Property -Name "groups" -Value $groups -Force
    $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}
