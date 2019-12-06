Function Add-DatabricksSecretScope
{
	<#
			.SYNOPSIS
			Creates a new secret scope.
			.DESCRIPTION
			Creates a new secret scope.
			Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#create-secret-scope
			.PARAMETER ScopeName 
			Scope name requested by the user. Scope names are unique. This field is required.
			.PARAMETER InitialManagePrincipal 
			The principal that is initially granted MANAGE permission to the created scope.
			.EXAMPLE
			New-DatabricksSecretScope -ScopeName "MySecretScope" -InitialManagePrincipal "users"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [string] [Alias("scope", "name", "scope_name")] $ScopeName, 
		[Parameter(Mandatory = $false, Position = 2, ValueFromPipeline = $true)] [string] [Alias("initial_manage_principal")] $InitialManagePrincipal = $null
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/secrets/scopes/create"
	}
	
	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			scope = $ScopeName 
		}
	
		$parameters | Add-Property -Name "initial_manage_principal" -Value $InitialManagePrincipal

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		# this call does not return any results
		#return $result
	}
}


Function Remove-DatabricksSecretScope
{
  <#
      .SYNOPSIS
      Deletes a secret scope.
      .DESCRIPTION
      Deletes a secret scope.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#delete-secret-scope
      .PARAMETER ScopeName 
      Name of the scope to delete. This field is required.
      .EXAMPLE
      Remove-DatabricksSecretScope -ScopeName "MyScope"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [Alias("scope")] [string] $ScopeName
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/secrets/scopes/delete"
    
    $ScopeName = $PSBoundParameters.ScopeName
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}


Function Get-DatabricksSecretScope
{
	<#
			.SYNOPSIS
			Lists all secret scopes available in the workspace.
			.DESCRIPTION
			Lists all secret scopes available in the workspace.
			Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#list-secret-scopes
			.EXAMPLE
			Get-DatabricksSecretScope
			.EXAMPLE
			#AUTOMATED_TEST:List Secret Scopes
			Get-DatabricksSecretScope

	#>
	[CmdletBinding()]
	param ()
	
	$requestMethod = "GET"
	$apiEndpoint = "/2.0/secrets/scopes/list"

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result.scopes
}


Function Add-DatabricksSecret
{
  <#
      .SYNOPSIS
      Inserts a secret under the provided scope with the given name. If a secret already exists with the same name, this command overwrites the existing secret's value. The server encrypts the secret using the secret scope's encryption settings before storing it. You must have WRITE or MANAGE permission on the secret scope.
      .DESCRIPTION
      Inserts a secret under the provided scope with the given name. If a secret already exists with the same name, this command overwrites the existing secret's value. The server encrypts the secret using the secret scope's encryption settings before storing it. You must have WRITE or MANAGE permission on the secret scope.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#put-secret
      .PARAMETER StringValue
      The value to be stored. Note that the value will be stored in UTF-8 (MB4) form.
      .PARAMETER BytesValue 
      The value to be stored. Note that the value will be stored as bytes.
      .PARAMETER ScopeName 
      The name of the scope to which the secret will be associated with. This field is required.
      .PARAMETER SecretName 
      A unique name to identify the secret. This field is required.
      .EXAMPLE
      Add-DatabricksSecret -ScopeName "MyScope" -SecretName "MyKey" -StringValue "MySecretValue"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("scope")] [string] $ScopeName, 
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("key")] [string] $SecretName,
		
    [Parameter(ParameterSetName = "StringValue", Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)] [Alias("string_value", "new_string_value")] [string] $StringValue, 
		
    [Parameter(ParameterSetName = "BytesValue", Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)] [Alias("bytes_value", "new_bytes_value")] [byte[]] $BytesValue
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/secrets/put"
    
    $ScopeName = $PSBoundParameters.ScopeName
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{}
    switch ($PSCmdlet.ParameterSetName) 
    { 
      "StringValue" {
        $parameters | Add-Property -Name "string_value" -Value $StringValue
			
      }

      "BytesValue" {
        $bytesBase64 = [System.Convert]::ToBase64String($BytesValue)
        $parameters | Add-Property -Name "bytes_value" -Value $bytesBase64
      }
    }

    $parameters | Add-Property -Name "scope" -Value $ScopeName
    $parameters | Add-Property -Name "key" -Value $SecretName
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}

Function Remove-DatabricksSecret
{
  <#
      .SYNOPSIS
      Deletes the secret stored in this secret scope. You must have WRITE or MANAGE permission on the secret scope.
      .DESCRIPTION
      Deletes the secret stored in this secret scope. You must have WRITE or MANAGE permission on the secret scope.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#delete-secret
      .PARAMETER ScopeName 
      The name of the scope that contains the secret to delete. This field is required.
      .PARAMETER Key
      Name of the secret to delete. This field is required.
      .EXAMPLE
      Remove-DatabricksSecret -ScopeName "MyScope" -SecretName "MySecret"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("scope", "name")] [string] $ScopeName, 
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("key")] [string] $SecretName
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/secrets/delete"
    
    $ScopeName = $PSBoundParameters.ScopeName
  }

  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
      key = $SecretName 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}


Function Get-DatabricksSecret
{
  <#
      .SYNOPSIS
      Lists the secret keys that are stored at this scope. This is a metadata-only operation; secret data cannot be retrieved using this API. Users need READ permission to make this call.
      .DESCRIPTION
      Lists the secret keys that are stored at this scope. This is a metadata-only operation; secret data cannot be retrieved using this API. Users need READ permission to make this call.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#list-secrets
      .PARAMETER ScopeName
      The name of the scope whose secrets you want to list. This field is required.
      .EXAMPLE
      Get-DatabricksSecret -ScopeName "MyScope"
      .EXAMPLE
      #AUTOMATED_TEST:List cluster zones
      $secretScopes = Get-DatabricksSecretScope
      $secretScopes[0] | Get-DatabricksSecret
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("scope", "name")] [string] $ScopeName
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/secrets/list"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result.secrets
  }
}


Function Add-DatabricksSecretScopeACL
{
  <#
      .SYNOPSIS
      Creates or overwrites the ACL associated with the given principal (user or group) on the specified scope point. In general, a user or group will use the most powerful permission available to them, and permissions are ordered as follows:
      .DESCRIPTION
      Creates or overwrites the ACL associated with the given principal (user or group) on the specified scope point. In general, a user or group will use the most powerful permission available to them, and permissions are ordered as follows:
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#put-secret-acl
      .PARAMETER ScopeName 
      The name of the scope to apply permissions to. This field is required.
      .PARAMETER Principal 
      The principal to which the permission is applied. This field is required.
      .PARAMETER Permission 
      The permission level applied to the principal. This field is required.
      .EXAMPLE
      Add-DatabricksSecretScopeACL -Scope "MyScope" -Principal "data-scientists" -Permission Read
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [string] $Principal, 
    [Parameter(Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)] [string] [ValidateSet("Manage", "Read", "Write")] $Permission
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope','name' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/secrets/acls/put"
    
    $ScopeName = $PSBoundParameters.ScopeName
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
      principal = $Principal 
      permission = $Permission.ToUpper() 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}


Function Remove-DatabricksSecretScopeACL
{
  <#
      .SYNOPSIS
      Deletes the given ACL on the given scope.
      .DESCRIPTION
      Deletes the given ACL on the given scope.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#delete-secret-acl
      .PARAMETER ScopeName
      The name of the scope to remove permissions from. This field is required.
      .PARAMETER Principal 
      The principal to remove an existing ACL from. This field is required.
      .EXAMPLE
      Remove-DatabricksSecretScopeACL -ScopeName "MyScope" -Principal "data-scientists"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("scope", "name")] [string] $ScopeName, 
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [string] $Principal
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope','name' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 

    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/secrets/acls/delete"
    
    $ScopeName = $PSBoundParameters.ScopeName
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
      principal = $Principal 
    }
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # this call does not return any results
    #return $result
  }
}


Function Get-DatabricksSecretScopeACL
{
  <#
      .SYNOPSIS
      Describes the details about the given ACL, such as the group and permission.
      .DESCRIPTION
      Describes the details about the given ACL, such as the group and permission.
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#get-secret-acl
      Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#list-secret-acl
      .PARAMETER ScopeName 
      The name of the scope to fetch ACL information from. This field is required.
      .PARAMETER Principal 
      The principal to fetch ACL information for. This field is required.
      .EXAMPLE
      Get-DatabricksSecretScopeACL -ScopeName "MyScope" -Principal "data-scientists"
  #>
  [CmdletBinding()]
  param
  (
    #[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
    [Parameter(Mandatory = $false, Position = 2)] [string] $Principal = $null
  )
  DynamicParam
  {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    $scopeValues = (Get-DynamicParamValues { Get-DatabricksSecretScope }).name
    New-DynamicParam -Name ScopeName -ValidateSet $scopeValues -Alias 'scope','name' -Mandatory -ValueFromPipelineByPropertyName -DPDictionary $Dictionary 
       
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/secrets/acls/list"
    
    $ScopeName = $PSBoundParameters.ScopeName
    
    if($Principal)
    {
      Write-Verbose "--$Principal--"
      $apiEndpoint = "/2.0/secrets/acls/get"
    }
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      scope = $ScopeName 
    }
	
    $parameters | Add-Property -Name "principal" -Value $Principal
	
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if($Principal)
    {
      # if a Principal was specified, we return the result as it is
      return $result
    }
    else
    {
      # if no Principal was specified, we return the ACLs as an array
      return $result.items # the object is called "items" even though it states "acls" in the docs!
    }
  }
}