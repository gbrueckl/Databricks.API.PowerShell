# PowerShell Module for Databricks

This repository contains the source code for the PowerShell module "DatabricksPS". The module can also be found in the public PowerShell gallery: https://www.powershellgallery.com/packages/DatabricksPS/

It works for Databricks on Azure and also AWS. The APIs are almost identical so I decided to bundle them in one single module. The official API documentations can be found here:

Azure Databricks - https://docs.azuredatabricks.net/api/latest/index.html

Databricks on AWS - https://docs.databricks.com/api/latest/index.html

# Release History
### v1.1.3.0: 
- Minor fix for Secrets API making -InitialManagePrincipal optional
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
Service Principals are special accounts in Azure Active Directory which can be used for automated tasks like CI/CD pipelines. You provide the Databricks workspace you want to connect to, the ClientID and a ClientSecret/ClientKey. ClientID and ClientSecret need to be wrapped into a PSCredential where the ClientID is the usernamen and ClientSecret/ClientKey is the password. The rest is very similar to the Username/Password autehntication except that you also need to specify the `-ServicePrincipal` flag. The official documentation can be found [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token) and is also persisted in this repository [here](https://github.com/gbrueckl/Databricks.API.PowerShell/blob/master/Docs/Authentication%20using%20AAD%20user.pdf)
```powershell
$credSP = Get-Credential
$tenantId = '93519689-1234-1234-1234-e4b9f59d1963'
$subscriptionId = '30373b46-5678-5678-5678-d5560532fc32'
$resourceGroupName = 'myResourceGroup'
$workspaceName = 'myDatabricksWorkspace'
$azureResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Databricks/workspaces/$workspaceName"
$clientId = 'db00e35e-1111-2222-3333-c8cc85e6f524'

$apiUrl = "https://westeurope.azuredatabricks.net"

Set-DatabricksEnvironment -ClientID $clientId -Credential $credSP -AzureResourceID $azureResourceId -TenantID $tenantId -ApiRootUrl $apiUrl -ServicePrincipal
```
