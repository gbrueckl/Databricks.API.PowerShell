# PowerShell Module for Databricks

This repository contains the source code for the PowerShell module "DatabricksPS". The module can also be found in the public PowerShell gallery: https://www.powershellgallery.com/packages/DatabricksPS/

It works for Databricks on Azure and also AWS. The APIs are almost identical so I decided to bundle them in one single module. The official API documentations can be found here:

Azure Databricks - https://docs.azuredatabricks.net/api/latest/index.html

Databricks on AWS - https://docs.databricks.com/api/latest/index.html

# Release History
Please check the [CHANGELOG.md](./CHANGELOG.md) for details on latest changes.

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
There are various ways to authenticate against the Databricks REST API of which some are unique to Azure:
- Personal Access token 
- Azure Active Directory (AAD) Username/Password (Azure only!)
- Azure Active Directory (AAD) Service Principal (Azure only!)

In additiont to those, the DatabricksPS module also integrates with other tools to derive the configuration and authentication. Currently these tools include:
- Azure DevOps Service Connections (Azure only!)
- Databricks CLI
- [Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az) (Azure only!)

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


## Azure DevOps Integration
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

## Databricks CLI Integration
The Databricks CLI Integration relies on the Databricks CLI being installed and configured on your agent/machine already. It basically requires the two environment variables `DATABRICKS_HOST` and `DATABRICKS_TOKEN` to be set and only works with Personal Access Tokens. If those two environment variables are set, you can use the following code in your PowerShell task to e.g. stop all available clusters:
```
Set-DatabricksEnvironment -UsingDatabricksCLIAuthentication
Get-DatabricksCluster | Stop-DatabricksCluster
```

## Azure Az module Integration
In the context of Azure, the Azure Az PowerShell module is the core of most solutions. To use the authentication provided by the Az module, you can simply use the switch `-UsingAzContext` and the `-AzureResourceID` and the DatabricksPS module will take care of the rest:
```powershell
# Connect to Azure using the Az module
Connect-AzAccount 

$subscriptionId = '30373b46-5678-5678-5678-d5560532fc32'
$resourceGroupName = 'myResourceGroup'
$workspaceName = 'myDatabricksWorkspace'
$azureResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Databricks/workspaces/$workspaceName"

Set-DatabricksEnvironment -UsingAzContext -AzureResourceID $azureResourceId
```

# Supported APIs and endpoints
The goal of the Databricks PS modules is to supports all available Databricks REST API endpoints. However, as the APIs are constantly evolving, some newer ones might not be implemented yet. If you are missing a recently added endpoint, please open a ticket in this repo and I will add it as soon as possible!