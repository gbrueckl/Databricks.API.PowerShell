Function Get-DatabricksClusterPolicy {
  <#
      .SYNOPSIS
      Lists all cluster policies or returns a specific policy for a given PolicyId.
      .DESCRIPTION
      Lists all cluster policies or returns a specific policy for a given PolicyId.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/policies.html#list
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/policies.html#get
      .PARAMETER PolicyID 
      The policy ID about which to retrieve information.
      .OUTPUT
      List of PSObjects with the following properties
      - job_id
      - settings
      .EXAMPLE
      Get-DatabricksClusterPolicy -PolicyID 123
      .EXAMPLE
      #AUTOMATED_TEST:List existing clusters
      Get-DatabricksClusterPolicy
  #>
  [CmdletBinding(DefaultParametersetname = "List")]
  param 
  (	
    [Parameter(ParameterSetName = "PoliycID", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] 
        [Alias("policy_id")] [string] $PolicyID,

    [Parameter(ParameterSetName = "List", Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] 
        [Alias("sort_column")] [ValidateSet('POLICY_CREATION_TIME', 'POLICY_NAME')] [int64] $SortColumn,
    [Parameter(ParameterSetName = "List", Mandatory = $false, Position = 2, ValueFromPipelineByPropertyName = $true)] 
        [Alias("sort_order")] [ValidateSet('ASC', 'DESC')] [string] $SortOrder
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/policies/clusters/list"
  }
	
  process {
    if ($PSBoundParameters.PolicyID) {
      Write-Verbose "PolicyID specified ($PolicyID)- using Get-API instead of List-API..."
      $apiEndpoint = "/2.0/policies/clusters/get?policy_id=$PolicyID"
    }

    #Set parameters
    Write-Verbose "Building Body/Parameters for final API call ..."
    $parameters = @{ }

    if ($PSCmdlet.ParameterSetName -eq "List")
    {
      $parameters | Add-Property -Name "sort_column" -Value $SortColumn
      $parameters | Add-Property -Name "sort_order" -Value $SortOrder
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if ($PSCmdlet.ParameterSetName -eq "List") {
      # if a List was requested, we return the result as an array of policies
      return $result.policies
    }
    else {
      # if a single PolicyID was specified, we return result as it is
      return $result
    }
  }
}


Function Add-DatabricksClusterPolicy {
  <#
			.SYNOPSIS
			Create a new policy with a given name and definition.
			.DESCRIPTION
			Create a new policy with a given name and definition.
			https://docs.microsoft.com/en-gb/azure/databricks/dev-tools/api/latest/policies#create
			.PARAMETER PolicyName 
			Cluster policy name. This must be unique. Length must be between 1 and 100 characters.
      .PARAMETER Definition 
			Policy definition JSON document expressed in Databricks Policy Definition Language. 
			.EXAMPLE
			Add-DatabricksClusterPolicy -PolicyName "Example Policy" -Definition "{\"spark_version\":{\"type\":\"fixed\",\"value\":\"next-major-version-scala2.12\",\"hidden\":true}}"
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("name")] [string] $PolicyName,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [string] $Definition
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/policies/clusters/create"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      name = $PolicyName
      definition = $Definition 
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Remove-DatabricksClusterPolicy {
  <#
			.SYNOPSIS
			Delete a policy. Clusters governed by this policy can still run, but cannot be edited.
			.DESCRIPTION
			Delete a policy. Clusters governed by this policy can still run, but cannot be edited.
			https://docs.microsoft.com/en-gb/azure/databricks/dev-tools/api/latest/policies#delete
			.PARAMETER PolicyID
			The ID of the policy to delete.
			.EXAMPLE
			Remove-DatabricksClusterPolicy -PolicyID "ABCD000000000000"
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("policy_id")] [string] $PolicyID
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/policies/clusters/delete"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      policy_id = $PolicyID
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # there is no result returned by the API
    #return $result
  }
}


Function Update-DatabricksClusterPolicy {
  <#
			.SYNOPSIS
			Update an existing policy. This may make some clusters governed by this policy invalid. For such clusters the next cluster edit must provide a confirming configuration, but otherwise they can continue to run.
			.DESCRIPTION
			Update an existing policy. This may make some clusters governed by this policy invalid. For such clusters the next cluster edit must provide a confirming configuration, but otherwise they can continue to run.
			https://docs.microsoft.com/en-gb/azure/databricks/dev-tools/api/latest/policies#edit
      .PARAMETER PolicyID
			The ID of the policy to update.
			.PARAMETER PolicyName 
			Cluster policy name. This must be unique. Length must be between 1 and 100 characters.
      .PARAMETER Definition 
			Policy definition JSON document expressed in Databricks Policy Definition Language. 
			.EXAMPLE
			Update-DatabricksClusterPolicy -PolicyID "695F078EB2000009" -PolicyName "My New Name" -Definition "{\"spark_version\":{\"type\":\"fixed\",\"value\":\"next-major-version-scala2.12\",\"hidden\":true}}"
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("policy_id")] [string] $PolicyID,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [Alias("name")] [string] $PolicyName,
    [Parameter(Mandatory = $true, Position = 3, ValueFromPipelineByPropertyName = $true)] [string] $Definition
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/policies/clusters/edit"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      policy_id = $PolicyID
    }

    $parameters | Add-Property -Name "name" -Value $PolicyName
    $parameters | Add-Property -Name "definition" -Value $Definition

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    # there is no result returned by the API
    #return $result
  }
}