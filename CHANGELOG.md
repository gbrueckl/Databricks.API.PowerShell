# Release History

## v1.12.0.0

- Added support for the first Unity Catalog APIs (`Catalog`, `StorageCredential`, `ExternalLocation`)
- Fixed issue with mandatory parameter for `New-DatabricksJobRun`
- Added `azureDevOpsServicesAad` as GitProvider

## v1.11.0.8

- Added `-CustomObjectType` to all `Permission`-cmdlets. Can be used with `-ObjectType 'CUSTOM'` to set/get arbitrary permissions

## v1.11.0.7

- Added support for `Cluster Policies` in all `Permission`-cmdlets

## v1.11.0.6

- Added support for string object as `-ClusterObject` in `Add-DatabricksCluster` and `Update-DatabricksCluster`

## v1.11.0.5

- Added new `-IncludeMetrics`swithc when running `Get-DatabricksSQLHistory`

## v1.11.0.3

- Removed validation of `-JobID` parameter in API version 2.1 (only worked PowerShell ISE)
- Fixed issue with permissions API

## v1.11.0.1

- Rework Jobs API implementation to work better with API version 2.1

## v1.11.0.0

- Fixed issue with SCIM API for groups
- Fixed issue with Permissions API

## v1.10.0.0

- Added new entitlements `workspace-access` and `databricks-sql-access` to SCIM APIs

## v1.9.9.18

- Fixed issues with conflicing parameters `NodeTypeID`and `InstancePoolID`
- Rework Instance Pool API implementation + tests

## v1.9.9.17

- Fixed issues with pipelining of hashtables and ordered hashtables

## v1.9.9.16

- Fixed issues with `Add-DatabricksCluster`

## v1.9.9.15

- Fixed issues with `Get-DatabricksInstancePool`

## v1.9.9.14

- Fixed issue with piping and `Update-DatabricksSQLWarehouse`

## v1.9.9.13

- Updates to the SQL Warehouse API (new parameters like `-EnableServerlessCompute`)
- Added automated tests for SQL Warehouse API
- Fixed issues with aliases
- Fixed issues with SQL Warehouse API

## v1.9.9.12

- Fixed issue when exporting a REPO folder via `Export-DatabricksEnvironment`
- Fixes with pipelining in SCIM API cmdlets
- Fixed issues with the SQL Warehouse API

## v1.9.9.11

- Add new flag `-UsingAzContext` for `Set-DatabricksEnvironment` to derive authentication and URL from the [Azure Az module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az)

## v1.9.9.10

- Add support for [Git Credentials API](https://docs.databricks.com/dev-tools/api/latest/gitcredentials.html)

## v1.9.9.9

- Make `Pin-DatabricksCluster` and `Unpin-DatabricksCluster` return an object containing the `cluster_id` for further piping into other cmdlets.

## v1.9.9.8

- Add parameter aliases to `Add-DatabricksCluster` and `Update-DatabricksCluster` to match the names used in the cluster definition (e.g. `cluster_name` for `-CusterName`)

## v1.9.9.7

- Add aliases for all cmdlets - e.g. `gdbrc` for `Get-DatabricksCluster`
- Fix minor issue with dictionaries/hashtables being passed as parameters
- Fix issue with encodings in combination with PowerShell Core

## v1.9.9.6

- Fix issue with removal of empty parameters in `Add-DatabricksCluster`

## v1.9.9.5

- Fix issue with Repos API and pulling Tags

## v1.9.9.4

- Add support for `-CustomKeys` when using `Get-DatabricksWorkspaceConfig`
- Add dedicated parameters for all known workspace configs to `Set-DatabricksWorkspaceConfig`

## v1.9.9.3

- Add support for `-CustomConfig` when using `Set-DatabricksWorkspaceConfig`

## v1.9.9.2

- Add better suppot for integration with CI/CD pipelines
- Azure DevOps: `Set-DatabricksEnvironment` now supports the new switch `-UsingAzureDevOpsServiceConnection` to be used with Azure DevOps CLI Task - see [Azure DevOps Integration](#azure-devops-integration)
- Databricks CLI: `Set-DatabricksEnvironment` now supports the new switch `-UsingDatabricksCLIAuthentication` to be used with any CI/CD tool and the Databricks CLI is already configured - see [Databricks CLI Integration](#databricks-cli-integration)

## v1.9.9.1

- Add `-Timeout` parameter to SCIM API `Get-*` cmdlets 

### v1.9.9.0

- Add support for SQL endpoints to the `*-DatabricksPermissions` cmdlets as described here [SQL Endpoint Permissions](https://docs.databricks.com/sql/user/security/access-control/sql-endpoint-acl.html#manage-sql-endpoint-permissions-using-the-api).
