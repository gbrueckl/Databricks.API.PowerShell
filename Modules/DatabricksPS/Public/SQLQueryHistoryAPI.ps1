Function Get-DatabricksSQLHistory {
  <#
      .SYNOPSIS
      List the history of queries through SQL endpoints. You can filter by user ID, endpoint ID, status, and time range.
      .DESCRIPTION
      List the history of queries through SQL endpoints. You can filter by user ID, endpoint ID, status, and time range.
      Official API Documentation: https://docs.databricks.com/sql/api/query-history.html#list
      .PARAMETER SQLEndpointIds 
      Filter results by SQL endpoint IDs.
      .PARAMETER UserIds 
      Filter results by User IDs.
      .PARAMETER Statuses 
      Filter results by statuses.
      .PARAMETER StartTimeFrom 
      Filter results by the query start time greater than -StartTimeFrom.
      .PARAMETER StartTimeTo 
      Filter results by the query start time less than -StartTimeTo.
      .PARAMETER MaxResults 
      Filter the number of results returned.
      .PARAMETER NextPageToken 
      The token for the next page in case paging in used.
      .EXAMPLE
      Get-DatabricksSQLHistory -SQLEndpintIds @("1234567890abcdef") -UserIds @("12345") -Statuses @("RUNNING", "QUEUED") -MaxResults 100
      
  #>
  [CmdletBinding(DefaultParametersetname = "Start/End MS")]
  param
  (
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "sql_endpoint_ids", "endpoint_id", "endpoint_ids", "id")] [string[]] $SQLEndpointIds,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("user_id", "user_ids")] [string[]] $UserIds,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("status")] [string[]] [ValidateSet("QUEUED", "RUNNING", "CANCELED", "FAILED", "FINISHED")] $Statuses,
    
    [Parameter(ParameterSetName = "Start/End MS", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("query_start_time_from_ms")] [int64] $StartTimeFromMS = -1,
    [Parameter(ParameterSetName = "Start/End MS", Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("query_start_time_to_ms")] [int64] $StartTimeToMS = -1,
    [Parameter(ParameterSetName = "Start/End DateTime", Mandatory = $true)] [Alias("query_start_time_from")] [datetime] $StartTimeFrom,
    [Parameter(ParameterSetName = "Start/End DateTime", Mandatory = $true)] [Alias("query_start_time_to")] [datetime] $StartTimeTo,
    
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("max_results")] [int] $MaxResults = -1,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("page_token", "next_page_token")] [string] $NextPageToken
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/history/queries"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $timeFilter = @{}
    
    if ($PSCmdlet.ParameterSetName -eq "Start/End DateTime") {
      $StartTimeFromMS = [Math]::Round(($StartTimeFrom).ToFileTime() / 10000000 - 11644473600)
      $StartTimeToMS = [Math]::Round(($StartTimeTo).ToFileTime() / 10000000 - 11644473600)
    }

    $timeFilter | Add-Property -Name "start_time_ms" -Value $StartTimeFromMS -NullValue -1
    $timeFilter | Add-Property -Name "end_time_ms" -Value $StartTimeToMS -NullValue -1

    $filters = @{}
    $filters | Add-Property -Name "endpoint_ids" -Value $SQLEndpointIds -NullValue @()
    $filters | Add-Property -Name "user_ids" -Value $UserIds -NullValue @()
    $filters | Add-Property -Name "statuses" -Value $Statuses -NullValue @()
    $filters | Add-Property -Name "query_start_time_range" -Value $timeFilter -NullValue @{}

    #Set parameters
    $parameters = @{}
    $parameters | Add-Property -Name "filter_by" -Value $filters -NullValue @{}
    $parameters | Add-Property -Name "max_results" -Value $MaxResults -NullValue -1
    $parameters | Add-Property -Name "page_token" -Value $NextPageToken

    # GET requests do not support a complex body/parameters so we need to convert it to JSON and append it to the URL/endpoint directly
    # https://stackoverflow.com/questions/3981564/cannot-send-a-content-body-with-this-verb-type

    if($PSVersionTable.PSVersion.Major -gt 5)
    {
      $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body ($parameters | ConvertTo-Json -Depth 5)
    }
    else {
      Write-Warning "Windows PowerShell and the .NET Framework do not allow complex GET request as used by this API.`nAll parameters except -MaxResults and -NextPageToken will be ignored!`nYou can consider using PowerShell CORE where this is supported.`nDetails can be found here https://github.com/dotnet/runtime/issues/25485"
      $parameters.Remove("filter_by")
      $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
    }

    return $result
  }
}