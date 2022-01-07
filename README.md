# PowerShell Module for Databricks

This repository contains the source code for the PowerShell module "DatabricksPS". The module can also be found in the public PowerShell gallery: https://www.powershellgallery.com/packages/DatabricksPS/

It works for Databricks on Azure and also AWS. The APIs are almost identical so I decided to bundle them in one single module. The official API documentations can be found here:

Azure Databricks - https://docs.azuredatabricks.net/api/latest/index.html

Databricks on AWS - https://docs.databricks.com/api/latest/index.html

# Release History
### v1.9.8.0: 
- Added support for [Token Management API](https://docs.databricks.com/dev-tools/api/latest/token-management.html) 
	- using new `-Admin` switch
- Improve usability of Workspace Config API
- added automated tests for Token API and Token Management API
- add new `-Me` switch to `Get-DatabricksSCIMUser` to get information of the currently authenticated user
### v1.9.7.0: 
- Added support for [Repos API](https://docs.databricks.com/dev-tools/api/latest/repos.html)
- Added support for [Jobs API v2.1](https://docs.databricks.com/dev-tools/api/latest/jobs.html) via a switch `JobsAPIVersion` on `Set-DatabricksEnvironment`
- Deprecation Projects API (`Pull-DatabricksProject`)
### v1.9.6.2: 
- Fix some documentation
### v1.9.6.1: 
- Fixed an issue with `Get-DatabricksSQLHistory` and Windows PowerShell
- Filters with `Get-DatabricksSQLHistory` are only supported with PowerShell CORE ([details](https://github.com/dotnet/runtime/issues/25485))
### v1.9.6.0: 
- Fixed an issue with `Get-DatabricksSQLHistory` and also improved it
- Added [Common Snippets](#common-snippets) to this README.md
### v1.9.5.3: 
- Minor extension for `Update-DatabricksCluster` cmdlet
- fix verbose logging so API key is only displayed in -Debug mode
### v1.9.5.1: 
- Minor fixes for `Update-DatabricksCluster` cmdlet
### v1.9.5.0: 
- Added support for [IP Access Lists API](https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html)
### v1.9.0.0: 
- Added support for [Permissions API](https://docs.databricks.com/dev-tools/api/latest/permissions.html)
- includes pipelining for existing object (e.g. cluster-object, job-object, ...)
### v1.8.1.0: 
- Update-DatabricksCluster now allows you to specify `-ClusterID` and `-ClusterObject` at the same time where the first one has priority. This can be used to update an existing cluster with the configuration of another cluster.
### v1.8.0.1: 
- add additional option to export SQL objects via `Export-DatabricksEnvironment` (experimental)
- added cmdlet to easily view results of Databricks command
- fix issue with DBFS file handle datatype
### v1.7.0.0: 
- Added support for v1.2 APIs ([Execution Context](https://docs.databricks.com/dev-tools/api/1.2/index.html#execution-context) and [Command Execution](https://docs.databricks.com/dev-tools/api/1.2/index.html#command-execution-1))
	- fully supports pipelining for easy use
### v1.6.2.0: 
- Fix issue with Cluster cmdlets to properly support pipelineing
- Added support for Instance Pools in Clulster cmdlets
### v1.6.0.0: 
- Add support for Project APIs (experimental, [link](https://docs.databricks.com/projects.html#projects-api-experimental)) 
- Added Workspace Config settings
### v1.5.0.0: 
- Add support for SQL Analytics APIs (experimental, [link](https://docs.microsoft.com/en-us/azure/databricks/sql/api/sql-endpoints))
### v1.3.1.0: 
- Add support for Workspace configs (get/set)
### v1.3.0.0: 
- Add support for Global Init Scripts
### v1.2.2.0: 
- Add -Entitlements parameter to Add-DatabricksSCIMGroup
- Some fixes for proper pipelining when working with Groups and SCIM APIs
- Add test-case for Security (SCIM, Groups, memberships, ...)
### v1.2.1.0: 
- Fixed issue with Import of already existing files and folders
### v1.2.0.1: 
- Add support for Azure backed Secret Scopes for non-standard Azure environments like AzureChinaCloud or AzureUSGovernment
### v1.2.0.0: 
- Add support for AAD authentication in non-standard Azure environments like AzureChinaCloud or AzureUSGovernment
### v1.1.4.0: 
- Fix Secrets API when creating Azure KeyVault Backed Secret Scopes.
### v1.1.3.0: 
- Minor fix for Secrets API making -InitialManagePrincipal optional.
### v1.1.2.0: 
- Changed -ApiRootUrl parameter to support any URL and not just a fixed list. 
- Added Get-DatabricksApiRootUrl cmdlet to be able to get a list of predefined API Root URLs
### v1.1.1.0: 
- Added new cmdlet Add-DatabricksClusterLocalLibrary to add a local library (.jar, .whl, ...) to a cluster with a single command
### v1.0.0.0: 
- Added Azure Active Directory (AAD) Authentication for Service Principals and Users

# Setup and Installation
The easiest way to install the PowerShell module is to use the PowerShell built-in Install-Module cmdlet:
```powershell
Install-Module -Name DatabricksPS
```

Alternatively you can also download this repository and copy the folder \Modules\DatabricksPS locally and install it from the local path, also using the Import-Module cmdlet:
```powershell
Import-Module "C:\MyPSModules\Modules\DatabricksPS"
```

# Usage
The module is designed to set the connection relevant properties once and they are used for all other cmdlets then. You can always update this information during your PS sessions to connect to different Databricks environments in the same session.
```powershell
$accessToken = "dapi123456789e672c4007052d4694a7c51"
$apiUrl = "https://westeurope.azuredatabricks.net"

Set-DatabricksEnvironment -AccessToken $accessToken -ApiRootUrl $apiUrl
```

Once the environment is setup, you can use the other cmdlets:
```powershell
Get-DatabricksWorkspaceItem -Path "/"
Export-DatabricksWorkspaceItem -Path "/TestNotebook1" -LocalPath "C:\TestNotebook1_Export.ipynb" -Format JUPYTER

Start-DatabricksJob -JobID 123 -NotebookParams @{myParameter = "test"}
```

Using pipelined cmdlets:
```powershell
# stop all clusters
Get-DatabricksCluster | Stop-DatabricksCluster

# create multiple directories
"/test1","/test2" | Add-DatabricksWorkspaceDirectory

# get all run outputs for a given job
Get-DatabricksJobRun -JobID 123 | Get-DatabricksJobRunOutput
```

# Common snippets
Below you can find a list of common snippets that I found useful and use very frequently. All snippets use the Personal Access Token for authentication but of course also work with Azure Active Directory user and service principal authentication (see [Authentication](#authentication)).
## Stop all clusters at the end of the day
```powershell
Set-DatabricksEnvironment -AccessToken "dapi123...def" -ApiRootUrl "https://westeurope.azuredatabricks.net"
Get-DatabricksCluster | Stop-DatabricksCluster
```

## Export a whole or single parts of a Databricks workspace
```powershell
Set-DatabricksEnvironment -AccessToken "dapi123...def" -ApiRootUrl "https://westeurope.azuredatabricks.net"
Export-DatabricksEnvironment -CleanLocalRootPath -LocalPath "C:\\my_export" -Artifacts @("Workspace", "Clusters", "Jobs")
```

## Import a whole or single parts of a Databricks workspace
```powershell
Set-DatabricksEnvironment -AccessToken "dapi123...def" -ApiRootUrl "https://westeurope.azuredatabricks.net"
Import-DatabricksEnvironment -LocalPath "C:\\my_export" -Artifacts @("Workspace", "Clusters", "Jobs")
```

## Calling a not yet supported/implemented API
The Databricks API is update frequently and it is pretty hard to keep everything up-to-date. So in case an API call you are looking for is not yet supported by this moduel, you can always execute the call manually leveraging the existing authentication:
```powershell
Set-DatabricksEnvironment -AccessToken "dapi123...def" -ApiRootUrl "https://westeurope.azuredatabricks.net"
$body = @{
      cluster_id = "1202-211320-brick1";
	  num_workers = 4
    }

Invoke-DatabricksApiRequest -Method "POST" -EndPoint "/2.0/clusters/resize" -Body $body
```


# Authentication
There are 3 ways to authenticate against the Databricks REST API of which 2 are unique to Azure:
- Personal Access token 
- Azure Active Directory (AAD) Username/Password (Azure only!)
- Azure Active Directory (AAD) Service Principal (Azure only!)

## Personal Access Token
This is the most straight forward authentication and works for both, Azure and AWS.
The official documentation can be found [here (Azure)](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/authentication) or [here (AWS)](https://docs.databricks.com/dev-tools/api/latest/authentication.html) and is also persisted in this repository [here](https://github.com/gbrueckl/Databricks.API.PowerShell/blob/master/Docs/Authentication%20using%20Azure%20Databricks%20personal%20access%20tokens.pdf).
```powershell
$accessToken = "dapi123456789e672c4007052d4694a7c51"
$apiUrl = "https://westeurope.azuredatabricks.net"

Set-DatabricksEnvironment -AccessToken $accessToken -ApiRootUrl $apiUrl
```

## Azure Active Directory (AAD) Username/Password
This authentication method is very similar to what you use when logging in interactively when accessing the Databricks web UI. You provide the Databricks workspace you want to connect to, the username and a password. The official documentation can be found [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token) and is also persisted in this repository [here](https://github.com/gbrueckl/Databricks.API.PowerShell/blob/master/Docs/Authentication%20using%20AAD%20user.pdf).
```powershell
$credUser = Get-Credential
$tenantId = '93519689-1234-1234-1234-e4b9f59d1963'
$subscriptionId = '30373b46-5678-5678-5678-d5560532fc32'
$resourceGroupName = 'myResourceGroup'
$workspaceName = 'myDatabricksWorkspace'
$azureResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Databricks/workspaces/$workspaceName"
$clientId = 'db00e35e-1111-2222-3333-c8cc85e6f524'

$apiUrl = "https://westeurope.azuredatabricks.net"

Set-DatabricksEnvironment -ClientID $clientId -Credential $credUser -AzureResourceID $azureResourceId -TenantID $tenantId -ApiRootUrl $apiUrl
```

## Azure Active Directory (AAD) Service Principal
Service Principals are special accounts in Azure Active Directory which can be used for automated tasks like CI/CD pipelines. You provide the Databricks workspace you want to connect to, the ClientID and a ClientSecret/ClientKey. ClientID and ClientSecret need to be wrapped into a PSCredential where the ClientID is the usernamen and ClientSecret/ClientKey is the password. The rest is very similar to the Username/Password authentication except that you also need to specify the `-ServicePrincipal` flag. The official documentation can be found [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token) and is also persisted in this repository [here](https://github.com/gbrueckl/Databricks.API.PowerShell/blob/master/Docs/Authentication%20using%20AAD%20user.pdf)
```powershell
$clientId = '12345678-6789-6789-6789-6e44bf2f5d11' # = Application ID
$clientSecret = 'tN4Lrez.=12345AgRx6w6kJ@6C.ap7Y'
$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credSP = New-Object System.Management.Automation.PSCredential($clientId, $secureClientSecret)
$tenantId = '93519689-1234-1234-1234-e4b9f59d1963'
$subscriptionId = '30373b46-5678-5678-5678-d5560532fc32'
$resourceGroupName = 'myResourceGroup'
$workspaceName = 'myDatabricksWorkspace'
$azureResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Databricks/workspaces/$workspaceName"

$apiUrl = "https://westeurope.azuredatabricks.net"

Set-DatabricksEnvironment -ClientID $clientId -Credential $credSP -AzureResourceID $azureResourceId -TenantID $tenantId -ApiRootUrl $apiUrl -ServicePrincipal
```

# Supported APIs and endpoints
- Clusters API ([Azure](https://docs.azuredatabricks.net/api/latest/clusters.html), [AWS](https://docs.databricks.com/api/latest/clusters.html))
- Groups API ([Azure](https://docs.azuredatabricks.net/api/latest/groups.html), [AWS](https://docs.databricks.com/api/latest/groups.html))
- Jobs API ([Azure](https://docs.azuredatabricks.net/api/latest/jobs.html), [AWS](https://docs.databricks.com/api/latest/jobs.html))
- Secrets API ([Azure](https://docs.azuredatabricks.net/api/latest/secrets.html), [AWS](https://docs.databricks.com/api/latest/secrets.html))
- Token API ([Azure](https://docs.azuredatabricks.net/api/latest/tokens.html), [AWS](https://docs.databricks.com/api/latest/tokens.html))
- Workspace API ([Azure](https://docs.azuredatabricks.net/api/latest/workspace.html), [AWS](https://docs.databricks.com/api/latest/workspace.html))
- Libraries API ([Azure](https://docs.azuredatabricks.net/api/latest/libraries.html), [AWS](https://docs.databricks.com/api/latest/libraries.html))
- DBFS API ([Azure](https://docs.azuredatabricks.net/api/latest/dbfs.html), [AWS](https://docs.databricks.com/api/latest/dbfs.html))
- Instance Profiles API ([AWS](https://docs.databricks.com/api/latest/instance-profiles.html))
- SCIM API ([Azure](https://docs.azuredatabricks.net/api/latest/scim.html), [AWS](https://docs.databricks.com/api/latest/scim.html))
- Instance Pools API ([Azure](https://docs.azuredatabricks.net/api/latest/instance-pools.html), [AWS](https://docs.databricks.com/dev-tools/api/latest/instance-pools.html))
- Cluster Policies API ([Azure](https://docs.azuredatabricks.net/api/latest/policies.html), [AWS](https://docs.databricks.com/dev-tools/api/latest/policies.html))
- Instance Profiles API ([AWS](https://docs.databricks.com/dev-tools/api/latest/instance-profiles.html))
- Global Init Scripts API ([AWS](https://docs.databricks.com/dev-tools/api/latest/global-init-scripts.html), [Azure](https://docs.microsoft.com/en-gb/azure/databricks/dev-tools/api/latest/global-init-scripts))
- Tokens API ([AWS](https://docs.databricks.com/dev-tools/api/latest/tokens.html), [Azure](https://docs.microsoft.com/en-gb/azure/databricks/dev-tools/api/latest/tokens))
- Workspace Config API ([AWS](https://docs.databricks.com/sql/api/sql-endpoints.html), [Azure](https://docs.microsoft.com/en-gb/azure/databricks/sql/api/sql-endpoints))
- SQL Analytics API ([AWS](https://docs.databricks.com/sql/api/sql-endpoints.html), [Azure](https://docs.microsoft.com/en-gb/azure/databricks/sql/api/sql-endpoints))
- SQL Analytics Query History API ([AWS](https://docs.databricks.com/sql/api/query-history.html), [Azure](https://docs.microsoft.com/en-gb/azure/databricks/sql/api/query-history))