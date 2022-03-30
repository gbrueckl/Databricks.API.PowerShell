
$script:WorkspaceCconfigKeys = @(
  "enableTokensConfig", 
  "maxTokenLifetimeDays", 
  "enableIpAccessLists", 
  "enableJobViewAcls",
  "enforceClusterViewAcls",
  "enforceWorkspaceViewAcls",
  "enableHlsRuntime",
  "enableDcs",
  "enableProjectTypeInWorkspace",
  "enableWorkspaceFilesystem",
  "enableProjectsAllowList",
  "projectsAllowList",
  "enable-X-Frame-Options",
  "enable-X-Content-Type-Options",
  "enable-X-XSS-Protection",
  "enableResultsDownloading",
  "enableUploadDataUis",
  "enableExportNotebook",
  "enableNotebookGitVersioning",
  "enableNotebookTableClipboard",
  "enableWebTerminal",
  "enableDbfsFileBrowser",
  "enableDatabricksAutologgingAdminConf",
  "mlflowRunArtifactDownloadEnabled",
  "mlflowModelServingEndpointCreationEnabled",
  "mlflowModelRegistryEmailNotificationsEnabled",
  "rStudioUserDefaultHomeBase",
  "storeInteractiveNotebookResultsInCustomerAccount"
)
Function Get-DatabricksWorkspaceConfig {
  <#
      .SYNOPSIS
      This request gets different information based on what you pass to keys parameter.
      .DESCRIPTION
      This request gets different information based on what you pass to keys parameter.
      Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/token-management.html#operation/get-configuration
      .PARAMETER Keys 
      List of predefined keys to retrieve from the workspace config.
      .PARAMETER CustomKeys
      List of keys to retrieve from the workspace config. If one of the keys does not exist, it will throw an error.
      .EXAMPLE
      Get-DatabricksWorkspaceConfig -Keys "enableTokensConfig"
      .EXAMPLE
      Get-DatabricksWorkspaceConfig -Keys "enableIpAccessLists"
  #>
  [CmdletBinding(DefaultParameterSetName = "Predefined")]
  param
  (
    [Parameter(ParameterSetName = "CustomKeys", Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)] [Alias("CustomConfig")] [string[]] $CustomKeys
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      
    New-DynamicParam -Name Keys -Type string[] -ParameterSetName "Predefined" -ValidateSet $script:WorkspaceCconfigKeys -Alias "Key" -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
  begin {
    $requestMethod = "GET"
    $apiEndpoint = "/2.0/workspace-conf"
  }
	
  process {
    if ($PSCmdlet.ParameterSetName -eq "CustomKeys") {
      $Keys = $CustomKeys
    }
    else
    {
      if(-not $PSBoundParameters.ContainsKey('Keys'))
      {
        # use all pre-defined keys
        $Keys = $script:WorkspaceCconfigKeys
      }
      else
      {
        $Keys = $PSBoundParameters.Keys
      }
    }
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    $parameters = @{
      keys = $Keys -join ","
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}


Function Set-DatabricksWorkspaceConfig {
  <#
			.SYNOPSIS
			This request sets different workspace settings based on the parameters that you set. For example, enable or disable personal access tokens, or set maximum token lifetime for new tokens. See parameters for details.
			.DESCRIPTION
			This request sets different workspace settings based on the parameters that you set. For example, enable or disable personal access tokens, or set maximum token lifetime for new tokens. See parameters for details.
			Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/token-management.html#operation/set-configuration
			.PARAMETER EnableTokensConfig 
			Enable or disable personal access tokens for this workspace.
      .PARAMETER MaxTokenLifetimeDays 
			Maximum token lifetime of new tokens in days, as an integer. If zero, new tokens are permitted to have no lifetime limit. Negative numbers are unsupported. WARNING: This limit only applies to new tokens, so there may be tokens with lifetimes longer than this value, including unlimited lifetime. Such tokens may have been created before the current maximum token lifetime was set. To review existing tokens, see the get tokens API.
      .PARAMETER EnableIpAccessLists
			The IP access list feature is enabled for the workspace if true and it is disabled if false. Note that these are String values, not booleans.
      .PARAMETER CustomConfig
      A dictionary containing the new settings you want to use.
			.EXAMPLE
			Set-DatabricksWorkspaceConfig -EnableTokensConfig $true
      .EXAMPLE
			Set-DatabricksWorkspaceConfig -MaxTokenLifetimeDays 90
      .EXAMPLE
			Set-DatabricksWorkspaceConfig -EnableIpAccessLists $false
	#>
  [CmdletBinding()]
  param
  (
    [Parameter(ParameterSetName = "CustomConfig", Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)] [hashtable] $CustomConfig
  )
  DynamicParam {
    #Create the RuntimeDefinedParameterDictionary
    $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    
    foreach($item in $script:WorkspaceCconfigKeys)
    {
      if($item -contains "enable" -or $item -contains "enforce")
      {
        New-DynamicParam -Name $item -Type bool -ParameterSetName "Predefined" -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
      }
      else {
        New-DynamicParam -Name $item -Type string -ParameterSetName "Predefined" -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
      }
      
    } 
    #return RuntimeDefinedParameterDictionary
    return $Dictionary
  }
	
  begin {
    $requestMethod = "PATCH"
    $apiEndpoint = "/2.0/workspace-conf"
  }
	
  process {
    Write-Verbose "Building Body/Parameters for final API call ..."

    #Set parameters
    if ($PSCmdlet.ParameterSetName -eq "CustomConfig") {
      $parameters = $CustomConfig
    }
    else {
      $parameters = @{ }

      foreach($param in $PSBoundParameters.GetEnumerator())
      {
        # only use predefined keys
        if(-not ($param.Key -in $script:WorkspaceCconfigKeys))
        {
          Continue
        }

        $parameters | Add-Property -Name $param.Key -Value $param.Value -Force
      }
    }

    $result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

    return $result
  }
}