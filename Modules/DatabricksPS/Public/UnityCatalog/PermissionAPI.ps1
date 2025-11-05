Function Get-UnityCatalogPermission {
	<#$
		.SYNOPSIS
		Get grants (privileges) for a Unity Catalog securable.
		.DESCRIPTION
		Retrieves the current privilege assignments for a Unity Catalog securable using the Grants GET endpoint.
		Official API Documentation: https://docs.databricks.com/api/workspace/grants/get
		.PARAMETER SecureableType 
		The Unity Catalog securable type, for example CATALOG, SCHEMA, TABLE, VIEW, FUNCTION, VOLUME, EXTERNAL_LOCATION, STORAGE_CREDENTIAL, METASTORE, SHARE, RECIPIENT, PROVIDER, CONNECTION.
		.PARAMETER SecureableName 
		The full name of the securable (for tables/views/functions use catalog.schema.name; for catalogs use catalog name; for external locations, storage credentials, etc. use the object name).
		.PARAMETER Principal 
		Optional principal (user, group, or service principal) to filter privilege assignments.
		.PARAMETER IncludeInherited 
		Include inherited privileges in the response (applies to non-effective endpoint).
		.PARAMETER Raw
		Return the raw API response instead of just the privilege assignments array.
		.PARAMETER Effective
		Use the effective permissions endpoint which returns the union of direct and inherited privileges.
		.EXAMPLE
		Get-UnityCatalogPermission -SecureableType CATALOG -SecureableName MyCatalog
		.EXAMPLE
		Get-UnityCatalogPermission -SecureableType TABLE -SecureableName main.default.my_table -Principal user@example.com
	#>
	[CmdletBinding()]
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("type", "securable_type")] [ValidateSet('METASTORE', 'CATALOG', 'SCHEMA', 'TABLE', 'VIEW', 'FUNCTION', 'VOLUME', 'EXTERNAL_LOCATION', 'STORAGE_CREDENTIAL', 'SHARE', 'RECIPIENT', 'PROVIDER', 'CONNECTION')] [string] $SecureableType,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("name", "full_name")] [string] $SecureableName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Principal,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("max_results")] [int] $MaxResults,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("next_page_token")] [string] $NextPageToken,
		[Parameter(Mandatory = $false)] [switch] $Raw,
		[Parameter(Mandatory = $false)] [switch] $Effective
	)
	begin {
		$requestMethod = "GET"
		$apiBase = "/2.1/unity-catalog/"
	}	
	process {
		# Build endpoint and execute
		if ($Effective.IsPresent) {
			$apiBase += "effective-"
		}
		$apiEndpoint = "$($apiBase)permissions/$SecureableType/$SecureableName"
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{}

		# Optional query parameters
		$parameters | Add-Property -Name "principal" -Value $Principal -Force
		$parameters | Add-Property -Name "max_results" -Value $MaxResults -Force
		$parameters | Add-Property -Name "next_page_token" -Value $NextPageToken -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($Raw.IsPresent) { 
			return $result 
		}
		if ($result.next_page_token) {
			Write-Warning "A next_page_token was found indicating additional repos are available. Please use -Raw to to retrieve it!"
		}
		return $result.privilege_assignments 
	}
}

Function Update-UnityCatalogPermission {
	<#
		.SYNOPSIS
		Update grants (privileges) on a Unity Catalog securable.
		.DESCRIPTION
		Updates privilege assignments for a Unity Catalog securable using the Grants PATCH endpoint.
		You can add new privileges, remove existing privileges, provide a complete list of privilege assignments, or pass change objects via pipeline.
		Official API Documentation: https://docs.databricks.com/api/workspace/grants/update
		.PARAMETER SecureableType 
		The Unity Catalog securable type, for example CATALOG, SCHEMA, TABLE, VIEW, FUNCTION, VOLUME, EXTERNAL_LOCATION, STORAGE_CREDENTIAL, METASTORE, SHARE, RECIPIENT, PROVIDER, CONNECTION.
		.PARAMETER SecureableName 
		The full name of the securable (for tables/views/functions use catalog.schema.name; for catalogs use catalog name; for external locations, storage credentials, etc. use the object name).
		.PARAMETER Principal
		The principal (user, group, or service principal) to grant or revoke privileges for.
		.PARAMETER Add
		Array of privileges to add for the specified principal. Valid privileges: ALL_PRIVILEGES, SELECT, MODIFY, CREATE, READ_VOLUME, WRITE_VOLUME, CREATE_CATALOG, CREATE_SCHEMA, CREATE_TABLE, CREATE_VIEW, CREATE_FUNCTION, CREATE_MODEL, CREATE_VOLUME, USE_CATALOG, USE_SCHEMA, EXECUTE, REFRESH, READ_FILES, WRITE_FILES, CREATE_EXTERNAL_LOCATION, CREATE_STORAGE_CREDENTIAL, CREATE_SHARE, CREATE_RECIPIENT, CREATE_PROVIDER, USE_CONNECTION, USE_SHARE, USE_RECIPIENT, USE_PROVIDER, SET_SHARE_PERMISSION, MANAGE.
		.PARAMETER Remove
		Array of privileges to remove for the specified principal. Valid privileges: ALL_PRIVILEGES, SELECT, MODIFY, CREATE, READ_VOLUME, WRITE_VOLUME, CREATE_CATALOG, CREATE_SCHEMA, CREATE_TABLE, CREATE_VIEW, CREATE_FUNCTION, CREATE_MODEL, CREATE_VOLUME, USE_CATALOG, USE_SCHEMA, EXECUTE, REFRESH, READ_FILES, WRITE_FILES, CREATE_EXTERNAL_LOCATION, CREATE_STORAGE_CREDENTIAL, CREATE_SHARE, CREATE_RECIPIENT, CREATE_PROVIDER, USE_CONNECTION, USE_SHARE, USE_RECIPIENT, USE_PROVIDER, SET_SHARE_PERMISSION, MANAGE.
		.PARAMETER Changes
		Array of change objects to apply. Each object should have 'principal' and optionally 'add' and/or 'remove' properties. Accepts pipeline input.
		.PARAMETER Raw
		Return the raw API response instead of just the privilege assignments array.
		.EXAMPLE
		# Add privileges for a user
		Update-UnityCatalogPermission -SecureableType CATALOG -SecureableName MyCatalog -Principal "user@example.com" -Add "SELECT", "MODIFY"
		.EXAMPLE
		# Add privileges for a group
		Update-UnityCatalogPermission -SecureableType TABLE -SecureableName main.default.my_table -Principal "data-engineers" -Add "ALL_PRIVILEGES"
		.EXAMPLE
		# Remove specific privileges
		Update-UnityCatalogPermission -SecureableType TABLE -SecureableName main.default.my_table -Principal "user@example.com" -Remove "MODIFY"
		.EXAMPLE
		# Add and remove in one call
		Update-UnityCatalogPermission -SecureableType SCHEMA -SecureableName main.analytics -Principal "analysts" -Add "SELECT" -Remove "MODIFY"
		.EXAMPLE
		# Use changes parameter with multiple principals
		$changes = @(
			@{ principal = "user@example.com"; add = @("SELECT"); remove = @("MODIFY") },
			@{ principal = "data-engineers"; add = @("ALL_PRIVILEGES") }
		)
		Update-UnityCatalogPermission -SecureableType CATALOG -SecureableName MyCatalog -Changes $changes
		.EXAMPLE
		# Pipeline multiple changes
		@(
			@{ principal = "user1@example.com"; add = @("SELECT") },
			@{ principal = "user2@example.com"; remove = @("MODIFY") },
			@{ principal = "user3@example.com"; add = @("MODIFY"); remove = @("EXECUTE") }
		) | Update-UnityCatalogPermission -SecureableType TABLE -SecureableName main.default.my_table
	#>
	[CmdletBinding(DefaultParameterSetName = "SimpleChange")]
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("type", "securable_type")] [ValidateSet('METASTORE', 'CATALOG', 'SCHEMA', 'TABLE', 'VIEW', 'FUNCTION', 'VOLUME', 'EXTERNAL_LOCATION', 'STORAGE_CREDENTIAL', 'SHARE', 'RECIPIENT', 'PROVIDER', 'CONNECTION')] [string] $SecureableType,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("name", "full_name")] [string] $SecureableName,
		[Parameter(ParameterSetName = "SingleChange", Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $Principal,
		[Parameter(ParameterSetName = "SingleChange", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [ValidateSet('ALL_PRIVILEGES', 'SELECT', 'MODIFY', 'CREATE', 'READ_VOLUME', 'WRITE_VOLUME', 'CREATE_CATALOG', 'CREATE_SCHEMA', 'CREATE_TABLE', 'CREATE_VIEW', 'CREATE_FUNCTION', 'CREATE_MODEL', 'CREATE_VOLUME', 'USE_CATALOG', 'USE_SCHEMA', 'EXECUTE', 'REFRESH', 'READ_FILES', 'WRITE_FILES', 'CREATE_EXTERNAL_LOCATION', 'CREATE_STORAGE_CREDENTIAL', 'CREATE_SHARE', 'CREATE_RECIPIENT', 'CREATE_PROVIDER', 'USE_CONNECTION', 'USE_SHARE', 'USE_RECIPIENT', 'USE_PROVIDER', 'SET_SHARE_PERMISSION', 'MANAGE')] [string[]] $Add,
		[Parameter(ParameterSetName = "SingleChange", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [ValidateSet('ALL_PRIVILEGES', 'SELECT', 'MODIFY', 'CREATE', 'READ_VOLUME', 'WRITE_VOLUME', 'CREATE_CATALOG', 'CREATE_SCHEMA', 'CREATE_TABLE', 'CREATE_VIEW', 'CREATE_FUNCTION', 'CREATE_MODEL', 'CREATE_VOLUME', 'USE_CATALOG', 'USE_SCHEMA', 'EXECUTE', 'REFRESH', 'READ_FILES', 'WRITE_FILES', 'CREATE_EXTERNAL_LOCATION', 'CREATE_STORAGE_CREDENTIAL', 'CREATE_SHARE', 'CREATE_RECIPIENT', 'CREATE_PROVIDER', 'USE_CONNECTION', 'USE_SHARE', 'USE_RECIPIENT', 'USE_PROVIDER', 'SET_SHARE_PERMISSION', 'MANAGE')] [string[]] $Remove,
		[Parameter(ParameterSetName = "BulkChanges", Mandatory = $true, ValueFromPipeline = $true)] [object[]] $Changes,
		[Parameter(Mandatory = $false)] [switch] $Raw
	)
	begin {
		$requestMethod = "PATCH"
		$apiBase = "/2.1/unity-catalog/permissions"
	}	
	process {
		# Build endpoint
		$apiEndpoint = "$apiBase/$SecureableType/$SecureableName"
		Write-Verbose "Building Body/Parameters for final API call ..."
		
		# Build request body based on parameter set
		if ($PSCmdlet.ParameterSetName -eq "SingleChange") {
			# Single principal change
			$Changes = @{}
			$Changes | Add-Property -Name "principal" -Value $Principal -Force
			$Changes | Add-Property -Name "add" -Value $Add -Force
			$Changes | Add-Property -Name "remove" -Value $Remove -Force
		}
		elseif ($PSCmdlet.ParameterSetName -eq "BulkChanges") {
			# Multiple changes from parameter or pipeline
		}

		$parameters = @{"changes" = $Changes}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($Raw.IsPresent) { 
			return $result 
		}
		return $result.privilege_assignments 
	}
}

