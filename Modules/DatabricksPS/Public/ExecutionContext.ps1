Function Get-DatabricksExecutionContext {
  <#
      .SYNOPSIS
      Create an execution context on a specified cluster for a given programming language.
      .DESCRIPTION
      Create an execution context on a specified cluster for a given programming language.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#execution-context
      .PARAMETER ClusterID 
      The id of an existing cluster you want to use.
      .PARAMETER Language 
      The language for which you want to create an execution context.
      .EXAMPLE
      Get-DatabricksExecutionContext -ClusterID "1202-211320-brick1" -Language Scala
      .EXAMPLE
      Get-DatabricksExecutionContext -ClusterID "1202-211320-brick1" -Language Pyspark
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [ValidateSet('scala', 'python', 'sql')] [string] $Language
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/1.2/contexts/create"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      language = $Language
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    # add original parameters so the returned value can be used properly for pipelining
    $ret = [PSCustomObject]@{
      context_id = $result.id
      cluster_id = $ClusterID
      language = $Language
    }

    return $ret
  }
}



Function Get-DatabricksExecutionContextStatus {
  <#
      .SYNOPSIS
      Show the status of an existing execution context.
      .DESCRIPTION
      Show the status of an existing execution context.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#execution-context
      .PARAMETER ClusterID 
      The id of an existing cluster you want to use.
      .PARAMETER ContextID 
      The id of the context for which to retrieve the status.
      .EXAMPLE
      Get-DatabricksExecutionContextStatus -ClusterID "1202-211320-brick1" -ContextID 6317282514101885389
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/1.2/contexts/status"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      contextId = $ContextID
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    return $result
  }
}


Function Remove-DatabricksExecutionContext {
  <#
      .SYNOPSIS
      Destroy an execution context.
      .DESCRIPTION
      Destroy an execution context.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#execution-context
      .PARAMETER ClusterID 
      The id of of the cluster on which you want to destroy the execution context.
      .PARAMETER ContextID 
      The id of the context that you want to destroy.
      .EXAMPLE
      Remove-DatabricksExecutionContext -ClusterID "1202-211320-brick1" -ContextID 6317282514101885389

  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/1.2/contexts/destroy"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      contextId = $ContextID
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    return $result
  }
}
