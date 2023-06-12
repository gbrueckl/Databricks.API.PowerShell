Function Get-UnityCatalogSchema {
	<#
		.SYNOPSIS
		Gets an array of schemas for a catalog in the metastore. If the caller is the metastore admin or the owner of the parent catalog, all schemas for the catalog will be retrieved. Otherwise, only schemas owned by the caller (or for which the caller has the USE_SCHEMA privilege) will be retrieved. There is no guarantee of a specific ordering of the elements in the array..DESCRIPTION
		Official API Documentation: https://docs.databricks.com/api/azure/workspace/schemas/list
		Official API Documentation: https://docs.databricks.com/api/azure/workspace/schemas/get
		.PARAMETER CatalogName 
		Name of parent catalog.
		.PARAMETER SchemaName 
		Name of schema, relative to parent catalog.
		.EXAMPLE
		Get-UnityCatalogSchema -CatalogName MyCatalog
		.EXAMPLE
		#AUTOMATED_TEST:List existing Unity Catalogs
		Get-UnityCatalogSchema 
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("catalog_name")] [string] $CatalogName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("name", "schema_name")] [string] $SchemaName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [switch] $Raw
	)
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.1/unity-catalog/schemas"
	}	
	process {
		If ($PSBoundParameters.ContainsKey("SchemaName")) {
			$apiEndpoint = "/2.1/unity-catalog/schemas/$SchemaName"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ 
			catalog_name = $CatalogName
		}

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($PSBoundParameters.ContainsKey("SchemaName") -or $Raw.IsPresent) {
			# if a CatalogName was specified, we return the result as it is
			return $result
		}
		else {
			# if no CatalogName was specified, we return the catalogs as an array
			return $result.schemas
		}
	}
}

Function Add-UnityCatalogSchema {
	<#
		.SYNOPSIS
		Creates a new schema for catalog in the Metatastore. The caller must be a metastore admin, or have the CREATE_SCHEMA privilege in the parent catalog.
		.DESCRIPTION
		Creates a new schema for catalog in the Metatastore. The caller must be a metastore admin, or have the CREATE_SCHEMA privilege in the parent catalog.
		https://docs.databricks.com/api/azure/workspace/schemas/create
		.PARAMETER CatalogName 
		Name of parent catalog.
		.PARAMETER SchemaName 
		Name of schema, relative to parent catalog.
		.PARAMETER StorageRoot 
		Storage root URL for managed tables within schema.
		.PARAMETER Properties
		A map of key-value properties attached to the securable.
		.PARAMETER Comment
		User-provided free-form text description.
		.EXAMPLE
		Add-UnityCatalogSchema -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("catalog_name")] $CatalogName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "schema_name")] $SchemaName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("storage_root")]$StorageRoot,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [hashtable] $Properties,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.1/unity-catalog/schemas"
	}
		
	process {    
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			name         = $SchemaName
			catalog_name = $CatalogName
		}

		$parameters | Add-Property -Name "storage_root" -Value $StorageRoot -Force
		$parameters | Add-Property -Name "properties" -Value $Properties -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Update-UnityCatalogSchema {
	<#
		.SYNOPSIS
		Creates a new schema for catalog in the Metatastore. The caller must be a metastore admin, or have the CREATE_SCHEMA privilege in the parent catalog.
		.DESCRIPTION
		Creates a new schema for catalog in the Metatastore. The caller must be a metastore admin, or have the CREATE_SCHEMA privilege in the parent catalog.
		https://docs.databricks.com/api/azure/workspace/schemas/create
		.PARAMETER CatalogName 
		Name of parent catalog.
		.PARAMETER SchemaName 
		Name of schema, relative to parent catalog.
		.PARAMETER StorageRoot 
		Storage root URL for managed tables within schema.
		.PARAMETER Properties
		A map of key-value properties attached to the securable.
		.PARAMETER Comment
		User-provided free-form text description.
		.EXAMPLE
		Add-UnityCatalogSchema -URL "https://github.com/jsmith/test" -Provider "gitHub" -Path "/Repos/Production/testrepo"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("catalog_name")] $CatalogName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "schema_name")] $SchemaName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("new_name", "new_schema_name")]$NewSchemaName,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Owner,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] [Alias("storage_root")]$StorageRoot,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [hashtable] $Properties,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Comment
	)
	begin {
		$requestMethod = "PATCH"
	}
	process {    
		# specify endpoint here to access the variables form the pipeline
		$apiEndpoint = "/2.1/unity-catalog/schemas/$($CatalogName).$($SchemaName)"

		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{}

		$parameters | Add-Property -Name "name" -Value $NewSchemaName -Force
		$parameters | Add-Property -Name "owner" -Value $Owner -Force
		$parameters | Add-Property -Name "storage_root" -Value $StorageRoot -Force
		$parameters | Add-Property -Name "properties" -Value $Properties -Force
		$parameters | Add-Property -Name "comment" -Value $Comment -Force

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
			
		return $result
	}
}

Function Remove-UnityCatalogSchema {
	<#
		.SYNOPSIS
		Deletes the catalog that matches the supplied name. The caller must be a metastore admin or the owner of the catalog.
		.DESCRIPTION
		Deletes the catalog that matches the supplied name. The caller must be a metastore admin or the owner of the catalog.
		Official API Documentation: https://docs.databricks.com/api/azure/workspace/catalogs/delete
		.PARAMETER CatalogName 
		Name of parent catalog.
		.PARAMETER SchemaName 
		Name of schema, relative to parent catalog.
		.EXAMPLE
		Delete-UnityCatalogSchema -CatalogName 123 -SchemaName "raw"
	#>
	param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("catalog_name")] $CatalogName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] [Alias("name", "schema_name")] $SchemaName
	)
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.1/unity-catalog/schemas/$($CatalogName).$($SchemaName)"

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result
	}
}