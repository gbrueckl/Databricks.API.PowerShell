Function Start-DatabricksCommand {
  <#
      .SYNOPSIS
      Run a command or file using an existing Execution Context.
      .DESCRIPTION
      Run a command or file using an existing Execution Context.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#command-execution-1
      .PARAMETER ClusterID 
      The id of an existing cluster you want to use.
      .PARAMETER Language 
      The language for which you want to create an execution context.
      .PARAMETER ContextID 
      The id of the context on which you want to run the command/file.
      .EXAMPLE
      Start-DatabricksCommand -ClusterID "1202-211320-brick1" -Language Scala -ContextID 6317282514101885389 -Command "sc.parallelize(1 to 10).collect"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [ValidateSet('scala', 'python', 'sql')] [string] $Language,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cmd")] [string] $Command
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/1.2/commands/execute"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      language = $Language
      contextId = $ContextID
      command = $command
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    # add original parameters so the returned value can be used properly for pipelining
    # need to use JSON conversion to get a PSCustomObject instead of HashTable
    $ret = [PSCustomObject]@{
      command_id = $result.id
      context_id = $ContextID
      cluster_id = $ClusterID
      language = $Language
    }

    return $ret
  }
}


Function Get-DatabricksCommandStatus {
  <#
      .SYNOPSIS
      Show the status of an existing command.
      .DESCRIPTION
      Show the status of an existing command.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#command-execution-1
      .PARAMETER ClusterID 
      The id of an existing cluster you want to use.
      .PARAMETER CommandID 
      The id of the command for which to retrieve the status.
      .PARAMETER ContextID 
      The id of the context for which to retrieve the status.
      .EXAMPLE
      Get-DatabricksExecutionContextStatus -ClusterID "1202-211320-brick1" -CommandID 5220029674192230006
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("command_id")] [string] $CommandID
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/1.2/commands/status"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      contextId = $ContextID
      commandId = $CommandID
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
      The id of of the cluster on which you want to cancel the command.
      .PARAMETER ContextID 
      The id of the context on which you want to cancel the command.
      .PARAMETER CommandID
      The id of the command you wan tto cancel
      .EXAMPLE
      Remove-DatabricksExecutionContext -ClusterID "1202-211320-brick1" -ContextID 6317282514101885389

  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("command_id")] [string] $CommandID
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/1.2/commands/cancel"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      clusterId = $ClusterID
      contextId = $ContextID
      commandId = $CommandID
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    return $result
  }
}


Function Get-DatabricksCommandResult {
  <#
      .SYNOPSIS
      Show the status of an existing command.
      .DESCRIPTION
      Show the status of an existing command.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/1.2/index.html#command-execution-1
      .PARAMETER ClusterID 
      The id of an existing cluster you want to use.
      .PARAMETER CommandID 
      The id of the command for which to retrieve the status.
      .PARAMETER ContextID 
      The id of the context for which to retrieve the status.
      .EXAMPLE
      Get-DatabricksExecutionContextStatus -ClusterID "1202-211320-brick1" -CommandID 5220029674192230006
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("cluster_id")] [string] $ClusterID, 
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("context_id")] [string] $ContextID,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("command_id")] [string] $CommandID,
    [Parameter(Mandatory = $false)] [switch] $AwaitCompletion
  )
  process {    
    $wait = $false
    do {
      if($wait) { Start-Sleep -Seconds 3 }
      else {$wait = $true }
      $apiResults = Get-DatabricksCommandStatus -ClusterID $ClusterID -ContextID $ContextID -CommandID $CommandID     
    } while ($AwaitCompletion -and $apiResults.status -notin @("Finished", "Cancelled", "Error"))
    

    if($apiResults.status -eq "Finished")
    {
      if($apiResults.results.resultType -eq "table")
      {
        $data = @()
        $schema = $apiResults.results.schema

        foreach($row in $apiResults.results.data)
        {
          $newRow = [PSCustomObject]@{}
          for ($i = 0; $i -lt $schema.Count; $i++) {
            $value = $row[$i] -as $schema[$i].type.trim('"')
            $newRow | Add-Member -NotePropertyName $schema[$i].name -NotePropertyValue $value
          }

          $data += $newRow
        }

        return $data
      }
      elseif($apiResults.results.resultType -eq "text") {
        return [string]($apiResults.results.data)
      }
      elseif($apiResults.results.resultType -eq "error") {
        Write-Error ($apiResults.results | ConvertTo-Json -Depth 10)
      }
    }
    elseif($apiResults.status -eq "Error")
    {
      Write-Error ($apiResults | ConvertTo-Json -Depth 10)
    }
    return $apiResults
  }
}