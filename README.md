# PowerShell Module for Databricks

This repository contains the source code for the PowerShell module "DatabricksPS". The module can also be found in the public PowerShell gallery: https://www.powershellgallery.com/packages/DatabricksPS/

It works for Databricks on Azure and also AWS. The APIs are almost identical so I decided to bundle them in one single module. The official API documentations can be found here:

Azure Databricks - https://docs.azuredatabricks.net/api/latest/index.html

Databricks on AWS - https://docs.databricks.com/api/latest/index.html

# Setup
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

Set-DatabricksEnvironment -AccessToken "$accessToken" -ApiRootUrl "$apiUrl"
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

# Supported APIs and endpoint
- Clusters API ([Azure](https://docs.azuredatabricks.net/api/latest/clusters.html), [AWS](https://docs.databricks.com/api/latest/clusters.html))
- Groups API ([Azure](https://docs.azuredatabricks.net/api/latest/groups.html), [AWS](https://docs.databricks.com/api/latest/groups.html))
- Jobs API ([Azure](https://docs.azuredatabricks.net/api/latest/jobs.html), [AWS](https://docs.databricks.com/api/latest/jobs.html))
- Secrets API ([Azure](https://docs.azuredatabricks.net/api/latest/secrets.html), [AWS](https://docs.databricks.com/api/latest/secrets.html))
- Token API ([Azure](https://docs.azuredatabricks.net/api/latest/tokens.html), [AWS](https://docs.databricks.com/api/latest/tokens.html))
- Workspace API ([Azure](https://docs.azuredatabricks.net/api/latest/workspace.html), [AWS](https://docs.databricks.com/api/latest/workspace.html))
- Libraries API ([Azure](https://docs.azuredatabricks.net/api/latest/libraries.html), [AWS](https://docs.databricks.com/api/latest/libraries.html))
- DBFS API ([Azure](https://docs.azuredatabricks.net/api/latest/dbfs.html), [AWS](https://docs.databricks.com/api/latest/dbfs.html))
- Instance Profiles API ([AWS](https://docs.databricks.com/api/latest/instance-profiles.html))

# Not yet supported APIs
- SCIM API ([Azure](https://docs.azuredatabricks.net/api/latest/scim.html), [AWS](https://docs.databricks.com/api/latest/scim.html))

