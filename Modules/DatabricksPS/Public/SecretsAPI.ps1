Function New-SecretScope
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
			New-SecretScope -Name "MyScope" -InitialManagePrincipal <initial_manage_principal>
			.EXAMPLE
			#AUTOMATED_TEST:Add secret scope
			$newFile = Add-DatabricksFSFile -Path "/myTestFolder/myFile1.txt" -Overwrite $true
			Close-DatabricksFSFile -Handle $newFile.handle
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $false, Position = 2)] [string] $InitialManagePrincipal = $null
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/scopes/create"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
	}
	
	$parameters | Add-Property -Name "initial_manage_principal" -Value $InitialManagePrincipal
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Remove-SecretScope
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
			Remove-SecretScope -Name "MyScope"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/scopes/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-SecretScope
{
	<#
			.SYNOPSIS
			Lists all secret scopes available in the workspace.
			.DESCRIPTION
			Lists all secret scopes available in the workspace.
			Official API Documentation: https://docs.databricks.com/api/latest/secrets.html#list-secret-scopes
			.EXAMPLE
			Get-SecretScope
	#>
	[CmdletBinding()]
	param ()

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/scopes/list"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result.scopes
}


Function Add-Secret
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
			Add-Secret -ScopeName "MyScope" -SecretName "MyKey" -StringValue "MySecretValue"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $SecretName,
		
		[Parameter(ParameterSetName = "StringValue", Mandatory = $true, Position = 3)] [string] $StringValue, 
		
		[Parameter(ParameterSetName = "BinaryValue", Mandatory = $true, Position = 3)] [byte[]] $BytesValue
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/put"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	switch ($PSCmdlet.ParameterSetName) 
	{ 
		"StringValue" {
			#Set parameters
			$parameters = @{
				string_value  = $StringValue
			}
		}

		"BytesValue" {
			#Set parameters
			$parameters = @{
				bytes_value  = $BytesValue
			}
		}
	}

	$parameters | Add-Property -Name "scope" -Value $ScopeName
	$parameters | Add-Property -Name "key" -Value $SecretName
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}

Function Remove-Secret
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
			Remove-Secret -ScopeName "MyScope" -SecretName "MySecret"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $SecretName
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
		key = $SecretName 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-Secret
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
			Get-Secret -ScopeName "MyScope"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/list"
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
	}
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result.secrets
}


Function Add-SecretScopeACL
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
			Add-SecretScopeACL -Scope "MyScope" -Principal "data-scientists" -Permission Read
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $Principal, 
		[Parameter(Mandatory = $true, Position = 3)] [string] [ValidateSet("Manage", "Read", "Write")] $Permission
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/acls/put"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
		principal = $Principal 
		permission = $Permission 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Remove-SecretScopeACL
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
			Remove-SecretScopeACL -ScopeName "MyScope" -Principal "data-scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $Principal
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/acls/delete"
	$requestMethod = "POST"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
		principal = $Principal 
	}
			
	$parameters = $parameters | ConvertTo-Json -Depth 10

	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	return $result
}


Function Get-SecretScopeACL
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
			Get-SecretScopeACL -ScopeName "MyScope" -Principal "data-scientists"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $ScopeName, 
		[Parameter(Mandatory = $false, Position = 2)] [string] $Principal = $null
	)

	Test-Initialized

	Write-Verbose "Setting final ApiURL ..."
	if($Principal -ne $null)
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/acls/list"
	}
	else
	{
		$apiUrl = Get-ApiUrl -ApiEndpoint "/2.0/secrets/acls/get"
	}
	$requestMethod = "GET"
	Write-Verbose "API Call: $requestMethod $apiUrl"

	#Set headers
	$headers = Get-RequestHeader

	Write-Verbose "Setting Parameters for API call ..."
	#Set parameters
	$parameters = @{
		scope = $ScopeName 
	}
	
	$parameters | Add-Property -Name "principal" -Value $Principal
			
	$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

	if($Principal -ne $null)
	{
		# if a Principal was specified, we return the result as it is
		return $result
	}
	else
	{
		# if no Principal was specified, we return the ACLs as an array
		return $result.acls
	}
}