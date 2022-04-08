# PowerShell Module for Databricks

This repository contains the source code for the PowerShell module "DatabricksPS". The module can also be found in the public PowerShell gallery: https://www.powershellgallery.com/packages/DatabricksPS/

It works for Databricks on Azure and also AWS. The APIs are almost identical so I decided to bundle them in one single module. The official API documentations can be found here:

Azure Databricks - https://docs.azuredatabricks.net/api/latest/index.html

Databricks on AWS - https://docs.databricks.com/api/latest/index.html

# Release History
### v1.9.9.7:
- Add aliases for all cmdlets - e.g. `gdbrc` for `Get-DatabricksCluster`
- Fix minor issue with dictionaries/hashtables being passed as parameters
- Fix issue with encodings in combination with PowerShell Core
### v1.9.9.6:
- Fix issue with removal of empty parameters in `Add-DatabricksCluster`
### v1.9.9.5:
- Fix issue with Repos API and pulling Tags
### v1.9.9.4:
- Add support for `-CustomKeys` when using `Get-DatabricksWorkspaceConfig`
- Add dedicated parameters for all known workspace configs to `Set-DatabricksWorkspaceConfig`
### v1.9.9.3:
- Add support for `-CustomConfig` when using `Set-DatabricksWorkspaceConfig`
### v1.9.9.2:
- Add better suppot for integration with CI/CD pipelines
	- Azure DevOps: `Set-DatabricksEnvironment` now supports the new switch `-UsingAzureDevOpsServiceConnection` to be used with Azure DevOps CLI Task - see [Azure DevOps Integration](#azure-devops-integration)
	- Databricks CLI: `Set-DatabricksEnvironment` now supports the new switch `-UsingDatabricksCLIAuthentication` to be used with any CI/CD tool and the Databricks CLI is already configured - see [Databricks CLI Integration](#databricks-cli-integration)
### v1.9.9.1:
- Add `-Timeout` parameter to SCIM API `Get-*` cmdlets 
### v1.9.9.0: 
- Add support for SQL endpoints to the `*-DatabricksPermissions` cmdlets as described here [SQL Endpoint Permissions](https://docs.databricks.com/sql/user/security/access-control/sql-endpoint-acl.html#manage-sql-endpoint-permissions-using-the-api).
### v1.9.8.1: 
- Fix issue with `Import-DatabricksEnvironment` where clusters were not imported correctly
### v1.9.8.0: 
- Add support for [Token Management API](https://docs.databricks.com/dev-tools/api/latest/token-management.html) 
	- using new `-Admin` switch
- Improve usability of Workspace Config API
- Add automated tests for Token API and Token Management API
- Add new `-Me` switch to `Get-DatabricksSCIMUser` to get information of the currently authenticated user
### v1.9.7.0: 
- Add support for [Repos API](https://docs.databricks.com/dev-tools/api/latest/repos.html)
- Add support for [Jobs API v2.1](https://docs.databricks.com/dev-tools/api/latest/jobs.html) via a switch `JobsAPIVersion` on `Set-DatabricksEnvironment`
- Deprecation Projects API (`Pull-DatabricksProject`)
### v1.9.6.2: 
- Fix some documentation
### v1.9.6.1: 
- Fix an issue with `Get-DatabricksSQLHistory` and Windows PowerShell
- Filters with `Get-DatabricksSQLHistory` are only supported with PowerShell CORE ([details](https://github.com/dotnet/runtime/issues/25485))
### v1.9.6.0: 
- Fix an issue with `Get-DatabricksSQLHistory` and also improved it
- Add [Common Snippets](#common-snippets) to this README.md
### v1.9.5.3: 
- Minor extension for `Update-DatabricksCluster` cmdlet
- Fix verbose logging so API key is only displayed in -Debug mode
### v1.9.5.1: 
- Minor fixes for `Update-DatabricksCluster` cmdlet
### v1.9.5.0: 
- Added support for [IP Access Lists API](https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html)
### v1.9.0.0: 
- Add support for [Permissions API](https://docs.databricks.com/dev-tools/api/latest/permissions.html)
- includes pipelining for existing object (e.g. cluster-object, job-object, ...)
### v1.8.1.0: 
- `Update-DatabricksCluster` now allows you to specify `-ClusterID` and `-ClusterObject` at the same time where the first one has priority. This can be used to update an existing cluster with the configuration of another cluster.
### v1.8.0.1: 
- Add additional option to export SQL objects via `Export-DatabricksEnvironment` (experimental)
- Add cmdlet to easily view results of Databricks command
- Fix issue with DBFS file handle datatype
### v1.7.0.0: 
- Added support for v1.2 APIs ([Execution Context](https://docs.databricks.com/dev-tools/api/1.2/index.html#execution-context) and [Command Execution](https://docs.databricks.com/dev-tools/api/1.2/index.html#command-execution-1))
	- fully supports pipelining for easy use
### v1.6.2.0: 
- Fix issue with Cluster cmdlets to properly support pipelineing
- Added support for Instance Pools in Clulster cmdlets
### v1.6.0.0: 
- Add support for Project APIs (experimental, [link](https://docs.databricks.com/projects.html#projects-api-experimental)) 
- Add Workspace Config settings
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
- Fix issue with Import of already existing files and folders
### v1.2.0.1: 
- Add support for Azure backed Secret Scopes for non-standard Azure environments like AzureChinaCloud or AzureUSGovernment
### v1.2.0.0: 
- Add support for AAD authentication in non-standard Azure environments like AzureChinaCloud or AzureUSGovernment
### v1.1.4.0: 
- Fix Secrets API when creating Azure KeyVault Backed Secret Scopes.
### v1.1.3.0: 
- Minor fix for Secrets API making -InitialManagePrincipal optional.
### v1.1.2.0: 
- Chang `-ApiRootUrl` parameter to support any URL and not just a fixed list. 
- Add `Get-DatabricksApiRootUrl` cmdlet to be able to get a list of predefined API Root URLs
### v1.1.1.0: 
- Add new cmdlet `Add-DatabricksClusterLocalLibrary` to add a local library (.jar, .whl, ...) to a cluster with a single command
### v1.0.0.0: 
- Add Azure Active Directory (AAD) Authentication for Service Principals and Users

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

**Using pipelined cmdlets:**
```powershell
# stop all clusters
Get-DatabricksCluster | Stop-DatabricksCluster

# create multiple directories
"/test1","/test2" | Add-DatabricksWorkspaceDirectory

# get all run outputs for a given job
Get-DatabricksJobRun -JobID 123 | Get-DatabricksJobRunOutput
```

**Using aliases:**
For all cmdlets that use standard verbs (e.g `Get-*`) aliases are created. In general they follow these patterns: Standard-Verb-Alias (e.g. `g` for `Get-`, `a` for `Add-`, ...) then `dbr` for `Databricks` and last all UpperCase characters (e.g `c` for `Cluster`) of the original function converted to lower case.
So `Get-DatabricksCluster` becomes `gdbrc`, etc. 
```powershell
# stop all clusters
gdbrc | spdbrc

# create multiple directories
"/test1","/test2" | adbrwd

# get all run outputs for a given job
gdbrjr -JobID 123 | gdbrjro
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

In additiont to those, the DatabricksPS module also integrates with other tools to derive the configuration and authentication. Currently these tools include:
- Azure DevOps Service Connections
- Databricks CLI

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

# Azure DevOps Integration
If you want to use DatabricksPS module in your Azure DevOps pipelines and do not want to manage your Personal Access Tokens but leverage the Azure DevOps Service Connections instead, you can use the following YAML task defintion:
```
- task: AzureCLI@2
  displayName: "DatabricksPS - Stop All Clusters"  
  inputs:
    azureSubscription: "MyServiceConnection"    
    addSpnToEnvironment: true
    scriptType: ps
    scriptLocation: inlineScript
	arguments: '$(DATABRICKS_URL) $(AzURE_RESOURCE_ID)'
    inlineScript: |
	  Set-DatabricksEnvironment -ApiRootUrl $1 -AzureResourceID $2 -UsingAzureDevOpsServiceConnection 
	  Get-DatabricksCluster | Stop-DatabricksCluster
    azurePowerShellVersion: latestVersion

```
The important part is to use AzureCLI which allows you to choose a Azure DevOps Service Connection and persist the authentication information as temporary environment variables by using `addSpnToEnvironment: true`. Unfortunatelly this is currently not possible using AzurePowerShell.

# Databricks CLI Integration
The Databricks CLI Integration relies on the Databricks CLI being installed and configured on your agent/machine already. It basically requires the two environment variables `DATABRICKS_HOST` and `DATABRICKS_TOKEN` to be set and only works with Personal Access Tokens. If those two environment variables are set, you can use the following code in your PowerShell task to e.g. stop all available clusters:
```
Set-DatabricksEnvironment -UsingDatabricksCLIAuthentication
Get-DatabricksCluster | Stop-DatabricksCluster
```

# Supported APIs and endpoints
The goal of the Databricks PS modules is to supports all available Databricks REST API endpoints. However, as the APIs are constantly evolving, some newer ones might not be implemented yet. If you are missing a recently added endpoint, please open a ticket in this repo and I will add it as soon as possible!