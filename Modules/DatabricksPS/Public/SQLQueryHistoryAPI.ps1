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
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("sql_endpoint_id", "sql_endpoint_ids")] [string[]] $SQLEndpointIds,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("user_id", "user_ids")] [string[]] $UserIds,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("statuses")] [string[]] [ValidateSet("QUEUED", "RUNNING", "CANCELED", "FAILED", "FINISHED")] $Statuses,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("query_start_time_from_ms", "user_ids")] [int64] $StartTimeFrom,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("query_start_time_to_ms", "user_ids")] [int64] $StartTimeTo,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("max_results")] [int] $MaxResults = -1,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("page_token", "next_page_token")] [string] $NextPageToken
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/sql/history/queries"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $startTimes = @{}
    $filters | Add-Property -Name "start_time_ms" -Value $StartTimeFrom
    $filters | Add-Property -Name "end_time_ms" -Value $StartTimeTo

    $filters = @{}
    $filters | Add-Property -Name "sql_endpoint_ids" -Value $SQLEndpointIds -NullValue @()
    $filters | Add-Property -Name "user_ids" -Value $UserIds -NullValue @()
    $filters | Add-Property -Name "statuses" -Value $Statuses -NullValue @()
    $filters | Add-Property -Name "query_start_time_range" -Value $startTimes -NullValue @{}

    #Set parameters
    $parameters = @{}

    $parameters | Add-Property -Name "filter_by" -Value $filters -NullValue @{}
    $parameters | Add-Property -Name "max_results" -Value $MaxResults -NullValue -1
    $parameters | Add-Property -Name "page_token" -Value $NextPageToken

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}