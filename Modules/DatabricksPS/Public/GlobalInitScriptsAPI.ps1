Function Add-DatabricksGlobalInitScript {
  <#
			.SYNOPSIS
			Create a new global init script in this workspace.
			.DESCRIPTION
			Create a new global init script in this workspace.
			Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html#operation/create-script
			.PARAMETER Name 
			The name of the script.
      .PARAMETER Script 
			The Base64-encoded content of the script. To upload a plain text script please use -AsPlainText
      .PARAMETER AsPlainText
			If specified, -Script is interpreted as plain text and encoded to Base64 internally before the upload.
      .PARAMETER Position 
			The position of a global init script, where 0 represents the first global init script to run, 1 is the second global init script to run, and so on.
      If you omit the position for a new global init script, it gets the last position. It runs after all current global init scripts. Setting any value greater than the position of the last script is equivalent to the last position. For example, suppose there are three existing scripts with positions 0, 1 and 2. Any position value of 3 or greater puts the script in the last position (3) If an explicit position value conflicts with an existing script, your request succeeds. The original script at that position and all later scripts have their position incremented by 1.
      .PARAMETER Enabled 
			Specifies whether the script is enabled. The script runs only if enabled.
			.EXAMPLE
			Add-DatabricksGlobalInitScript -Name "MyScript" -Script "echo Hello World" -AsPlainText -Position 1 -Enabled $true
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("script_name")] [string] $Name,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true)] [string] $Script,
    [Parameter(Mandatory = $false, Position = 3, ValueFromPipelineByPropertyName = $false)] [switch] $AsPlainText,
    [Parameter(Mandatory = $false, Position = 4, ValueFromPipelineByPropertyName = $true)] [int64] $Position,
    [Parameter(Mandatory = $false, Position = 5, ValueFromPipelineByPropertyName = $true)] [bool] $Enabled = $false
  )
	
  begin {
    $requestMethod = "POST"
    $apiEndpoint = "/2.0/global-init-scripts"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if($AsPlainText) {
      $Script = $Script | ConvertTo-Base64 -Encoding ([Text.Encoding]::UTF8)
    }
    #Set parameters
    $parameters = @{
      name = $Name
      script = $Script
      position = $Position
      enabled = $Enabled
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}

Function Get-DatabricksGlobalInitScript {
  <#
      .SYNOPSIS
      Get a list of all global init scripts for this workspace. This returns all properties for each script but not the script contents. To retrieve the contents of a script, use the get a global init script operation.
      .DESCRIPTION
      Get a list of all global init scripts for this workspace. This returns all properties for each script but not the script contents. To retrieve the contents of a script, use the get a global init script operation.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html#operation/get-scripts
      .PARAMETER ScriptID 
      (Optional) The ID of a single script to return. If not specified, all scripts are returned
      .EXAMPLE
      Get-DatabricksGlobalInitScript
      .EXAMPLE
      Get-DatabricksGlobalInitScript -ScriptID 63D1236F6D2950C8
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("script_id", "id")] [string] $ScriptID
  )
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/global-init-scripts"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    if($ScriptID)
    {
      $apiEndpoint += "/$ScriptID"
    }
    #Set parameters
    $parameters = @{
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    if($ScriptID)
    {
      return $result
    }
    else {
      return $result.scripts
    }
  }
}

Function Remove-DatabricksGlobalInitScript {
  <#
      .SYNOPSIS
      Delete a global init script.
      .DESCRIPTION
      Delete a global init script.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html#operation/delete-script
      .PARAMETER ScriptID 
      The ID of the global init script to remove.
      .EXAMPLE
      Remove-DatabricksGlobalInitScript -ScriptID 63D1236F6D2950C8
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("script_id", "id")] [string] $ScriptID
  )
  
  begin {
    $requestMethod = "DELETE"
    $apiEndpoint = "/2.0/global-init-scripts"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$ScriptID"

    #Set parameters
    $parameters = @{
    }
		
    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint

    return $result
  }
}


Function Update-DatabricksGlobalInitScript {
  <#
			.SYNOPSIS
			Update a global init script, specifying only the fields to change. All fields are optional. Unspecified fields retain their current value.
			.DESCRIPTION
			Update a global init script, specifying only the fields to change. All fields are optional. Unspecified fields retain their current value.
			Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html#operation/update-script
      .PARAMETER ScriptID 
      The ID of the global init script to update.
			.PARAMETER Name 
			The name of the script.
      .PARAMETER Script 
			The Base64-encoded content of the script. To upload a plain text script please use -AsPlainText
      .PARAMETER AsPlainText
			If specified, -Script is interpreted as plain text and encoded to Base64 internally before the upload.
      .PARAMETER Position 
			The position of a global init script, where 0 represents the first global init script to run, 1 is the second global init script to run, and so on.
      If you omit the position for a new global init script, it gets the last position. It runs after all current global init scripts. Setting any value greater than the position of the last script is equivalent to the last position. For example, suppose there are three existing scripts with positions 0, 1 and 2. Any position value of 3 or greater puts the script in the last position (3) If an explicit position value conflicts with an existing script, your request succeeds. The original script at that position and all later scripts have their position incremented by 1.
      .PARAMETER Enabled 
			Specifies whether the script is enabled. The script runs only if enabled.
			.EXAMPLE
			Update-DatabricksGlobalInitScript -ScriptID 63D1236F6D2950C8  -Name "MyNewScript" -Script "echo Hello New World " -AsPlainText -Position 2 -Enabled $false
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("script_id", "id")] [string] $ScriptID,
    [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true)] [Alias("script_name")] [string] $Name,
    [Parameter(Mandatory = $false, Position = 2, ValueFromPipelineByPropertyName = $true)] [string] $Script,
    [Parameter(Mandatory = $false, Position = 3, ValueFromPipelineByPropertyName = $false)] [switch] $AsPlainText,
    [Parameter(Mandatory = $false, Position = 4, ValueFromPipelineByPropertyName = $true)] [int64] $Position,
    [Parameter(Mandatory = $false, Position = 5, ValueFromPipelineByPropertyName = $true)] [bool] $Enabled = $false
  )
	
  begin {
    $requestMethod = "PATCH"
    $apiEndpoint = "/2.0/global-init-scripts"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    $apiEndpoint += "/$ScriptID"

    if($AsPlainText) {
      $Script = $Script | ConvertTo-Base64 -Encoding ([Text.Encoding]::UTF8)
    }
    #Set parameters
    $parameters = @{
      name = $Name
      script = $Script
      position = $Position
      enabled = $Enabled
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}