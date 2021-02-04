Function Pull-DatabricksProject {
  <#
      .SYNOPSIS
      The Projects API fetch-and-checkout endpoint allows you to fetch the latest changes from the git remote and check them out. This can be useful if you have a production, testing, or staging project that you want to update to the latest version of a branch before running a job.
      .DESCRIPTION
      The Projects API fetch-and-checkout endpoint allows you to fetch the latest changes from the git remote and check them out. This can be useful if you have a production, testing, or staging project that you want to update to the latest version of a branch before running a job.
      Official API Documentation: https://docs.databricks.com/projects.html#projects-api-experimental
      .PARAMETER Path 
      The absolute path of the project.
      .PARAMETER Branch 
      The branch to fetch and check out. If you provide the current branch, the latest changes will be fetched and merged (equivalent of git pull). If you specify a new branch, it will be published to the remote.
      .PARAMETER StartPoint 
      (Optional) Start point when checking out a new branch. This can be another branch, a commit or a tag.
      The new branch will be published to the remote.

      Note: We don’t support resetting existing branches using a start point.

      If the start point doesn’t match the current head of an existing branch, the API will return an INVALID_STATE error.
      .EXAMPLE
      Pull-DatabricksProject -Path "/Projects/user@example.com/project" -Branch "master"
      .EXAMPLE
      Pull-DatabricksProject -Path "/Projects/user@example.com/project" -Branch "branch-0.1" -StartPoint "tags/release-0.1"
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
    [Parameter(Mandatory = $true, Position = 2)] [string] $Branch, 
    [Parameter(Mandatory = $false, Position = 3)] [Alias("start_point")] [string] $StartPoint
  )
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/projects/fetch-and-checkout"
  }
	
  process {    
    Write-Verbose "Building Body/Parameters for final API call ..."
    #Set parameters
    $parameters = @{
      path = $Path
      branch = $Branch
    }

    $parameters | Add-Property -Name "start_point" -Value $StartPoint -Force
			
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters
		
    return $result
  }
}
