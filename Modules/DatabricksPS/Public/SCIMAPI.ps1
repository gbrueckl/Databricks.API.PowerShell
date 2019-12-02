Function Get-DatabricksSCIMUser
{
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
    
    if($PSCmdlet.ParameterSetName -eq "ByUserID")  
    { 
      $apiEndpoint = "/2.0/preview/scim/v2/Users/$UserID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}

    if($PSCmdlet.ParameterSetName -eq 'List') 
    {
      $parameters | Add-Property -Name "filter" -Value $Filter -Force
    }
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -Accept 'application/scim+json'

    if ($PSCmdlet.ParameterSetName -eq "List" -and $Format -eq "List")  
    { 
      return $result.Resources 
    }
    
    return $result
  }
}

Function Add-DatabricksSCIMUser
{
  <#
      .SYNOPSIS
      Admin users: Create a user in the Databricks workspace.
      .DESCRIPTION
      Admin users: Create a user in the Databricks workspace.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/scim.html#create-user
      .PARAMETER UserName
      The username of the user to add. Usually an email address.
      .PARAMETER Groups
       A list of existing Databricks group names
      .PARAMETER Entitlements
      A list of Entitlements/Permissions the user should be assigned
      .EXAMPLE
      Add-DatabricksSCIMUser -UserName John.doe@test.com -Groups admins -Entitlements allow-cluster-create -Verbose
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)] [Alias("user_name")] [string] $UserName,
    [Parameter(Mandatory = $False)] [ValidateSet('allow-instance-pool-create', 'allow-cluster-create')][string[]] $Entitlements
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupValues = (Get-DynamicParamValues { Get-DatabricksSCIMGroup }).displayName
    New-DynamicParam -Name Groups -ValidateSet $groupValues -Alias 'group_name' -Type string[] -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/preview/scim/v2/Users"
    
    $Groups = $PSBoundParameters.Groups
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}
    
    $groupIDs = @((Get-DatabricksSCIMGroup | Where-Object { $_.displayName -in $Groups}).id | ForEach-Object { @{value = $_ } })
    $entitlementValues = @($Entitlements | ForEach-Object { @{value = $_ } })
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:User") -Force
    $parameters | Add-Property -Name "userName" -Value $UserName -Force
    $parameters | Add-Property -Name "groups" -Value $groupIDs -Force
    $parameters | Add-Property -Name "entitlements" -Value $entitlementValues -Force
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Remove-DatabricksSCIMUser
{
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
    #[Parameter(Mandatory = $True)] [Alias("user_id")] [string] $UserID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $userIdValues = (Get-DynamicParamValues { Get-DatabricksSCIMUser }).id
    New-DynamicParam -Name UserID -ValidateSet $userIdValues -Alias 'user_id' -Mandatory -ValueFromPipelineByPropertyName -Type string -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "DELETE"

    $UserID = $PSBoundParameters.UserID
    
    $apiEndpoint = "/2.0/preview/scim/v2/Users/$UserID"
  }
	
  process {
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Get-DatabricksSCIMGroup
{
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
    
    if($PSCmdlet.ParameterSetName -eq "ByGroupID")  
    { 
      $apiEndpoint = "/2.0/preview/scim/v2/Groups/$GroupID"
    }
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}

    if($PSCmdlet.ParameterSetName -eq 'List') 
    {
      $parameters | Add-Property -Name "filter" -Value $Filter -Force
    }
    
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -Accept 'application/scim+json'

    if ($PSCmdlet.ParameterSetName -eq "List" -and $Format -eq "List")  
    { 
      return $result.Resources 
    }
    
    return $result
  }
}

Function Add-DatabricksSCIMGroup
{
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
    [Parameter(Mandatory = $True)] [Alias("group_name")] [string] $GroupName
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $userIdValues = (Get-DynamicParamValues { Get-DatabricksSCIMUser }).id
    New-DynamicParam -Name MemberUserIDs -ValidateSet $userIdValues -Type string[] -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/preview/scim/v2/Groups"
    
    $MemberUserIDs = $PSBoundParameters.MemberUserIDs
  }
	
  process {
    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{}
    
    $MemberUserIDs = @($MemberUserIDs | ForEach-Object { @{value = $_ } })
    
    $parameters | Add-Property -Name "schemas" -Value @("urn:ietf:params:scim:schemas:core:2.0:Group") -Force
    $parameters | Add-Property -Name "displayName" -Value $GroupName -Force
    $parameters | Add-Property -Name "members" -Value $MemberUserIDs -Force
        
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters -ContentType 'application/scim+json'
    
    return $result
  }
}

Function Remove-DatabricksSCIMGroup
{
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
    #[Parameter(Mandatory = $True)] [Alias("group_id")] [string] $GroupID
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $groupIdValues = (Get-DynamicParamValues { Get-DatabricksSCIMGroup }).id
    New-DynamicParam -Name GroupID -ValidateSet $groupIdValues -Alias 'group_id' -Mandatory -ValueFromPipelineByPropertyName -Type string -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  
  begin {
    $requestMethod = "DELETE"

    $GroupID = $PSBoundParameters.GroupID
    
    $apiEndpoint = "/2.0/preview/scim/v2/Groups/$GroupID"
  }
	
  process {
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -ContentType 'application/scim+json'
    
    return $result
  }
}