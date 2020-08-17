Function Invoke-DatabricksApiRequest {
	<#
			.SYNOPSIS
			Lists all jobs or returns a specific job for a given JobID.
			.DESCRIPTION
			Lists all jobs or returns a specific job for a given JobID. 
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#list
			Official API Documentation: https://docs.databricks.com/api/latest/jobs.html#get
			.PARAMETER Method 
			The type of request you want to invoke. Will usually be GET or POST
			.PARAMETER EndPoint
			The API endpoint that you want to invoke. Please check the API reference for valid values. Example: "/2.0/jobs/list"
			.PARAMETER Body
			Some endpoints also support a body to supply additional information. This can be specified here. For POST requests, this is usually a JSON-string whereas for GET it is usually a hashtable which is then converted to URL parameters
			.EXAMPLE
			Invoke-DatabricksApiRequest -Method GET -EndPoint "/2.0/jobs/list"
	#>
	[CmdletBinding()]
	param 
	(	
		[Parameter(Mandatory = $true, Position = 1)] [string] [ValidateSet("DEFAULT", "DELETE", "GET", "HEAD", "MERGE", "OPTIONS", "PATCH", "POST", "PUT", "TRACE")] $Method,
		[Parameter(Mandatory = $true, Position = 2)] [string] $EndPoint,
		[Parameter(Mandatory = $false, Position = 3)] $Body,
		[Parameter(Mandatory = $false, Position = 4)] $ContentType,
		[Parameter(Mandatory = $false, Position = 5)] $Accept
	)
	Test-Initialized	 

	Write-Verbose "Setting final ApiURL ..."
	$apiUrl = Get-ApiUrl -ApiEndpoint $EndPoint
	Write-Verbose "API Call: $Method $apiUrl"
	
	#Set headers
	Write-Verbose "Building Headers ..."
	$headers = Get-RequestHeader
	$headers | Add-Property -Name "Content-Type" -Value $ContentType -Force
	$headers | Add-Property -Name "Accept" -Value $Accept -Force
	Write-Verbose "Headers: `n$($headers | Out-String)"
	
	if ($Method -eq "GET") {	
		Write-Verbose "GET request - showing URL parameters as Key-Value pairs ..."
		Write-Verbose "Body: `n$($Body | Out-String)"
	}
	else {
		# for POST requests we have to convert the body to JSON
		Write-Verbose "$($Method.ToUpper()) request - converting Body to JSON ..."
		$Body = $Body | ConvertTo-Json -Depth 20
		
		Write-Verbose "Body: `n$($Body)"
	}

	$psCmd = "Invoke-RestMethod ``
	-Uri '$apiUrl' ``
	-Method $Method ``
	-Headers @$(($headers | ConvertTo-Json -Depth 20).Replace('":', '" =').Replace('",', '";')) ``
	-Body '$(($Body | Out-String).Trim('"').Replace('\r', '').Replace('\n', ''))' ``
	-Verbose"
	Write-Verbose "Executing the following nativ PowerShell command: `n# -----------------------------------------------`n$psCmd"

	if($script:dbApiCallRetryCount -gt 0)
	{	
		$retry = 0
		do {
			try {
				$result = Invoke-RestMethod -Uri $apiUrl -Method $Method -Headers $headers -Body $Body
				# exit loop after successful execution
				break
			} 
			catch {
				$retry += 1
				if ($retry -le $script:dbApiCallRetryCount) {
					Write-Warning $_.Exception
					Write-Warning $_
					Write-Information "Retrying API call ($retry of $($script:dbApiCallRetryCount) retries) ..."
					Start-Sleep -Seconds $script:dbApiCallRetryWait
				}
				else {
					throw $_
				}
			}				
		}
		while ($retry -le $script:dbApiCallRetryCount)
	}
	else {
		$result = Invoke-RestMethod -Uri $apiUrl -Method $Method -Headers $headers -Body $Body
	}	
	
	Write-Verbose "Response: $($result | ConvertTo-Json -Depth 10)"
	
	return $result
}

Function Set-DatabricksEnvironment {
	<#
			.SYNOPSIS
			Sets global module config variables AccessToken, CloudProvider and ApirRootUrl    
			.DESCRIPTION
			Sets global module config variables AccessToken, CloudProvider and ApirRootUrl    
			.PARAMETER AccessToken
			The AccessToken to use to access the Databricks API
			For example: dapi1234abcd32101691ded20b53a1326285
			.PARAMETER ApiRootUrl
			The URL of the API. 
			For Azure, this could be 'https://westeurope.azuredatabricks.net'
			For AWS, this could be 'https://abc-12345-xaz.cloud.databricks.com'
			.PARAMETER CloudProvider
			The CloudProvider where the Databricks workspace is hosted. Can either be 'Azure' or 'AWS'.
			If not provided, it is derived from the ApiRootUrl parameter and/or the type of authentication
			.PARAMETER Credential
			The Powershell credential to use when using AAD authentication.
			.PARAMETER ClientID
			The ID of the Azure Active Directory (AAD) application that was deployed to use AAD authentication with Databricks.
			If used in combination with -ServicePrincipal this value is ignored and is overwritten using the Usernamen from -Credential.
			.PARAMETER TenantID
			The ID of the Azure Active Directory (AAD). (optional)
			.PARAMETER AzureResourceID
			This is the ID of the workspace appliance resource in Azure. You must​ provide this ID if the Databricks workspace is not provisioned yet (such that there is no effective workspace org ID). It can be composed using the Azure subscription ID, resource group name, and workspace resource name. 
			Example: /subscriptions/<<SubscriptionID>>/resourceGroups/<<ResourceGroupName>>/providers/Microsoft.Databricks/workspaces/<<WorkspaceName>>
			.PARAMETER OrgID
			The organization ID of the Databricks workspace.
			You can find the workspace org ID in the Databricks URL, for example: https://<region>.azuredatabricks.net/?o=<​org_id​> 
			.PARAMETER SubscriptionID
			The Azure subscription ID in which the Databricks workspace resides.
			A GUID, e.g. 058a2e1e-1234-1234-1234-5c4c3e31e36e
			.PARAMETER ResourceGroupName
			The name of the ResourceGroup in which the Databricks workspace resides.
			.PARAMETER WorkspaceName
			The name of the Databricks workspace.
			.PARAMETER ServicePrincipal
			A switch indicating -Credential is a Service Principal which will be used for Authentication.
			.PARAMETER DynamicParameterCacheTimeout
			To improve performance during development dynamic paramters can be cached. This setting controls the number of seconds these values are persisted before the API is queried again for more recent values.
			.PARAMETER ApiCallRetryCount
			Number of times an API call is tried before an actual error is thrown.
			.PARAMETER ApiCallRetryWait
			Number of seconds to wait before retrying an API call.
			.EXAMPLE
			Set-DatabricksEnvironment -AccessToken "dapi1234abcd32101691ded20b53a1326285" -ApiRootUrl "https://abc-12345-xaz.cloud.databricks.com"
			.EXAMPLE
			Set-DatabricksEnvironment -AccessToken "dapi1234abcd32101691ded20b53a1326285" -ApiRootUrl "https://westeurope.azuredatabricks.net"
			.EXAMPLE
			$azureResourceId = '/subscriptions/fb1e20c4-1234-1234-1234-f92a9ac35db4/resourceGroups/myResourceGroupName/providers/Microsoft.Databricks/workspaces/myDatabricksResource'
			$cred = Get-Credential
			Set-DatabricksEnvironment -ClientID '058a2e1e-1234-1234-1234-5c4c3e31e36e' -Credential $cred -AzureResourceID $azureResourceId -ApiRootUrl "https://westeurope.azuredatabricks.net"
			
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "DatabricksApi", Mandatory = $true, Position = 1)] [string] $AccessToken,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceID", Mandatory = $true, Position = 1)]
		[Parameter(ParameterSetName = "AADAuthenticationOrgID", Mandatory = $true, Position = 1)]
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 1)][PSCredential] $Credential,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceID", Mandatory = $true, Position = 2)]
		[Parameter(ParameterSetName = "AADAuthenticationOrgID", Mandatory = $true, Position = 2)]
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 2)][string] $ClientID,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceID", Mandatory = $true, Position = 4)]
		[Parameter(ParameterSetName = "AADAuthenticationOrgID", Mandatory = $true, Position = 4)]
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 4)] [string] $TenantID,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceID", Mandatory = $true, Position = 3)] [string] $AzureResourceID,
		
		[Parameter(ParameterSetName = "AADAuthenticationOrgID", Mandatory = $true, Position = 3)] [string] $OrgID,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 3)] [string] $SubscriptionID,
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 5)] [string] $ResourceGroupName,
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $true, Position = 6)] [string] $WorkspaceName,
		
		[Parameter(ParameterSetName = "AADAuthenticationResourceID", Mandatory = $false, Position = 7)]
		[Parameter(ParameterSetName = "AADAuthenticationOrgID", Mandatory = $false, Position = 7)]
		[Parameter(ParameterSetName = "AADAuthenticationResourceDetails", Mandatory = $false, Position = 7)][switch] $ServicePrincipal,

		[Parameter(Mandatory = $false, Position = 2)] [int] $DynamicParameterCacheTimeout = 5,
		[Parameter(Mandatory = $false, Position = 3)] [int] $ApiCallRetryCount = -1,
		[Parameter(Mandatory = $false, Position = 4)] [int] $ApiCallRetryWait = 10,

		[Parameter(Mandatory = $false, Position = 5)] [string] $CustomApiRootUrl
	)
	DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		
		New-DynamicParam -Name ApiRootUrl -ValidateSet $script:dbApiRootUrls -DPDictionary $Dictionary
			
		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}

	begin {
		Write-Verbose "Setting [System.Net.ServicePointManager]::SecurityProtocol to [System.Net.SecurityProtocolType]::Tls12 ..."
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
		Write-Verbose "Done!"
	}

	process {
		$x = Clear-ScriptVariables

		if (-not $PSBoundParameters.ApiRootUrl -and -not $PSBoundParameters.CustomApiRootUrl) {
			Write-Error "Parameter -ApiRootUrl or -CustomApiRootUrl needs to be specified!"
		}
		elseif ($PSBoundParameters.CustomApiRootUrl) {
			$ApiRootUrl = $PSBoundParameters.CustomApiRootUrl
		}
		else {
			$ApiRootUrl = $PSBoundParameters.ApiRootUrl
		}
		
		#region Dynamic Parameter Caching
		Write-Verbose "Setting Dynamic Parameter Cache Timeout to $DynamicParameterCacheTimeout seconds ..."
		$script:dbDynamicParameterCacheTimeout = $DynamicParameterCacheTimeout
		#endregion
		
		#region Dynamic Parameter Caching
		Write-Verbose "Setting API Call Retry Count to $ApiCallRetryCount retries ..."
		$script:dbApiCallRetryCount = $ApiCallRetryCount
		#endregion
		
		#region Dynamic Parameter Caching
		Write-Verbose "Setting API Call Retry Wait to $ApiCallRetryWait seconds ..."
		$script:dbApiCallRetryWait = $ApiCallRetryWait
		#endregion

		#region check ApiRootUrl
		$paramToCheck = 'ApiRootUrl'
		Write-Verbose "Checking if Parameter -$paramToCheck was provided ..."
		if ($ApiRootUrl -ne $null) {
			Write-Verbose "$paramToCheck provided! Setting global $paramToCheck ..."
			$script:dbApiRootUrl = $ApiRootUrl.Trim('/') + "/api"
			Write-Verbose "Done!"
		}
		else {
			Write-Warning "Parameter -$paramToCheck was not provided!"
		}

		Write-Verbose "Trying to derive CloudProvider from ApiRootUrl ..."
		Write-Verbose "Checking if ApiRootUrl contains '.azuredatabricks.' ..."
		if ($ApiRootUrl -ilike "*.azuredatabricks.*") {
			Write-Verbose "'.azuredatabricks.' found in ApiRootUrl - Setting CloudProvider to 'Azure' ..."
			$script:dbCloudProvider = "Azure"
		}
		else {
			Write-Verbose "'.azuredatabricks.' not found in ApiRootUrl - Setting CloudProvider to 'AWS' ..."
			$script:dbCloudProvider = "AWS"
		}
		Write-Verbose "Done!"
		#endregion

		#region Databricks API Key
		if ($PSCmdlet.ParameterSetName -eq "DatabricksApi") {
			Write-Verbose "Using Databricks API authentication via API Token ..."
			$script:dbAuthenticationProvider = "DatabricksApi" 
				
			$script:dbAuthenticationHeader = @{
				"Authorization" = "Bearer $AccessToken"
			}
		}
		#endregion
		#region AAD Authentication using Resource
		elseif ($PSCmdlet.ParameterSetName -ilike "AADAuthenticationResource*") {
			$script:dbAuthenticationProvider = "AADAuthentication" 
			
			if ($PSCmdlet.ParameterSetName -eq "AADAuthenticationResourceDetails") {
				Write-Verbose "Using AAD authentication with Azure Resource Details ..."
				$AzureResourceID = "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Databricks/workspaces/$WorkspaceName"
			}
			elseif ($PSCmdlet.ParameterSetName -eq "AADAuthenticationResourceID") {
				Write-Verbose "Using AAD authentication with Azure ResourceID ..."
				
				$paramToCheck = 'ApiRootUrl'
				$wildCardPattern = '/subscriptions/*/resourceGroups/*/providers/Microsoft.Databricks/workspaces/*'
				Write-Verbose "Checking format of -$paramToCheck ..."
				
				if (-not ($AzureResourceID -ilike $wildCardPattern)) {
					Write-Error "Invalid -$paramToCheck provided! it has to match the following pattern: $wildCardPattern"
				}
				
				Write-Verbose "Parameter -$paramToCheck has a valid format!"
			}
				
			$script:dbAuthenticationHeader = @{
				"X-Databricks-Azure-Workspace-Resource-Id" = $AzureResourceID
			}
		}
		#endregion
		#region AAD Authentication using Org ID
		elseif ($PSCmdlet.ParameterSetName -eq "AADAuthenticationOrgID") {
			Write-Verbose "Using AAD authentication with Databricks Org ID ..." 
			$script:dbAuthenticationProvider = "AADAuthentication" 
				
			$script:dbAuthenticationHeader = @{
				"X-Databricks-Org-Id" = $OrgID
			}
		}
		#endregion
		#region AAD Authentication General
		if ($PSCmdlet.ParameterSetName.StartsWith("AADAuthentication")) {
			$script:dbCloudProvider = "Azure"
			$authUrl = "https://login.windows.net/$TenantID/oauth2/token/"

			Write-Verbose "Getting AAD access token ..."
			if ($ServicePrincipal) {
				Write-Verbose "Using Service Principal authentication flow ..."

				$headers = @{
					"Content-Type" = "application/x-www-form-urlencoded"
				}
				
				$body = @{
					"resource"      = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # Resource ID for AzureDatabricks, this is fixed!
					"grant_type"    = "client_credentials"
					"client_id"     = $Credential.UserName
					"client_secret" = $Credential.GetNetworkCredential().Password
				}

				Write-Verbose "API Call: POST $authUrl"
				Write-Verbose "Body: `n$($Body | Out-String)"
				
				$authResultLoginApp = Invoke-RestMethod -Uri $authUrl -Method POST -Headers $headers -Body $body

				$body["resource"] = "https://management.core.windows.net/" # Resource ID for AzureDatabricks, this is fixed!

				Write-Verbose "API Call: POST $authUrl"
				Write-Verbose "Body: `n$($Body | Out-String)"
				
				$authResultMgmt = Invoke-RestMethod -Uri $authUrl -Method POST -Headers $headers -Body $body

				$script:dbAuthenticationHeader["Authorization"] = "$($AuthResultLoginApp.token_type) $($authResultLoginApp.access_token)"
				$script:dbAuthenticationHeader["X-Databricks-Azure-SP-Management-Token"] = $authResultMgmt.access_token
			}
			else {
				Write-Verbose "Using Username/Password authentication flow ..."
				
				$body = @{
					"resource"   = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # Resource ID for AzureDatabricks, this is fixed!
					"grant_type" = "password"
					"client_id"  = $ClientId
					"username"   = $Credential.UserName
					"password"   = $Credential.GetNetworkCredential().Password
					"scope"      = "openid"
				}
				Write-Verbose "API Call: POST $authUrl"
				Write-Verbose "Body: `n$($Body | Out-String)"
				
				$authResult = Invoke-RestMethod -Uri $authUrl -Method POST -Body $body
				
				$script:dbAuthenticationHeader["Authorization"] = "$($authResult.token_type) $($authResult.access_token)"
			}
		} 
		#endregion	
		
		$script:dbInitialized = $true
	}
}

Function Clear-DatabricksEnvironment {
	<#
			.SYNOPSIS
			Clears the current DatabricksPS environment and removes all settings and references
			.DESCRIPTION
			Clears the current DatabricksPS environment and removes all settings and references
			.EXAMPLE
			Clear-DatabricksEnvironment
	#>
	[CmdletBinding()]
	param ()

	Clear-ScriptVariables
}

Function Test-DatabricksEnvironment {
	<#
			.SYNOPSIS
			Runs the most simple operation possible that should work on any Databricks environment - listing all items in DBFS under "/"
			.DESCRIPTION
			Runs the most simple operation possible that should work on any Databricks environment - listing all items in DBFS under "/"
			Official API Documentation: https://docs.databricks.com/api/latest/workspace.html#list
			.EXAMPLE
			Test-DatabricksEnvironment
	#>
	[CmdletBinding()]
	param ()

	$requestMethod = "GET"
	$apiEndpoint = "/2.0/dbfs/list"		

	Write-Verbose "Building Body/Parameters for final API call ..."
	#Set parameters
	$parameters = @{
		path = "/" 
	}
	
	$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

	return $result.files
}

Function Clear-DatabricksCachedDynamicParameterValue {
	<#
			.SYNOPSIS
			Clears all cached values for Dynamic Parameters if -UseDynamicParameterValueCaching was used during Set-DatabricksEnvironment
			.DESCRIPTION
			Clears all cached values for Dynamic Parameters if -UseDynamicParameterValueCaching was used during Set-DatabricksEnvironment
			.PARAMETER DynamicParameterName
			Unique Name of the Dynamic Parameter
			.EXAMPLE
			Clear-DatabricksCachedDynamicParameterValue
	#>
	[CmdletBinding()]
	param ()
	DynamicParam {
		#Create the RuntimeDefinedParameterDictionary
		$Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

		$values = $script:dbCachedDynamicParamValues.Keys
		New-DynamicParam -Name DynamicParameterName -ValidateSet $values -ValueFromPipelineByPropertyName -DPDictionary $Dictionary
        
		#return RuntimeDefinedParameterDictionary
		return $Dictionary
	}
	begin {
		
	}
	process {
		$DynamicParameterName = $PSBoundParameters.DynamicParameterName
		
		if ($DynamicParameterName) {
			$script:dbCachedDynamicParamValues.Remove($DynamicParameterName)
		}
		else {
			$script:dbCachedDynamicParamValues = @{ }
		}
	}
}

Function Set-DatabricksDynamicParameterCacheTimeout {
	<#
			.SYNOPSIS
			Set the timeout in seconds for how long Cached Dynamic Parameter Values are valid (e.g. ClusterID, JobID, ...)
			.DESCRIPTION
			Set the timeout in seconds for how long Cached Dynamic Parameter Values are valid (e.g. ClusterID, JobID, ...)
			.PARAM Seconds
			Number of seconds the Cached Dynamic PArameter Values are valid
			.EXAMPLE
			Set-DatabricksDynamicParameterCacheTimeout -Seconds 10
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)] [int] $Seconds
	)

	$script:dbDynamicParameterCacheTimeout = $Seconds
}

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

