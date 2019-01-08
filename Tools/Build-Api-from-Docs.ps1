function Get-DocumentationItem($html, $name)
{
	$docItemHtml = $html.ParsedHtml.body.getElementsByTagName('div') | Where-Object { $_.getAttributeNode('class').Value -eq 'section' -and $_.getAttributeNode('id').Value -eq $name}
	$docItemHtml
}

function Get-ApiEndpointDetails($docItemHtml)
{
	# get Endpoint and Method
	$endpointTableHtml = ($docItemHtml.getElementsByTagName("table"))[0] # the first table contains the Endpoint and Method
	$endpointTableRows = $endpointTableHtml.getElementsByTagName("tr")
	$row = $endpointTableRows[1] # first row are the headers, we need the second row for the details
	$cols = $row.getElementsByTagName("td") # get single columns
	$endpoint = $cols[0].innerText
	$method = $cols[1].innerText.ToUpper()
	
	# get Details Link
	$docLinkHtml = ($docItemHtml.getElementsByTagName("a")) | Where-Object { $_.getAttributeNode('class').Value -eq 'headerlink' }
	$docLink = $documentationUri + $docLinkHtml[0].hash
	
	# get Description
	$descriptionHtml = $docItemHtml.getElementsByTagName("p")
	$description = $descriptionHtml[0].innerText.Replace("Example of request:", "").Replace("An example response:", "").Trim()
	
	# get Parameters
	$parametersTableHtml = ($docItemHtml.getElementsByTagName("table"))[1] # the second table contains the Parameters
	$parametersTableRows = $parametersTableHtml.getElementsByTagName("tr")
	
	$parameters = @()
	foreach($row in $parametersTableRows)
	{
		$cols = $row.getElementsByTagName("td")
		
		if($cols[0].nodeName -eq "TD") # only take detail rows, not headers
		{
			$paramName = $cols[0].innerText
			$paramType = $cols[1].innerText.ToLower()
			$paramDescription = $cols[2].innerText
			$paramMandatory = $paramDescription.Contains("This field is required")
			$paramNamePS = (Get-Culture).TextInfo.ToTitleCase($paramName)			
			$param = @{ 
				name = $paramName
				namePS = $paramNamePS
				type = $paramType
				description = $paramDescription
				mandatory = $paramMandatory
			}
			
			$parameters += $param
		}
	}
	
	$apiDetails = @{
		endpoint = 	$endpoint
		method = $method
		link = $docLink
		description = $description
		parameters = $parameters
	}
	
	$apiDetails
}

function Get-PSFunctionTemplateFromApiDetails($apiDetails, $psFunctionName)
{
	# process Array of parameters
	$parametersDocumentation = ''
	$parametersDefinition = ''
	$parametersBody = ''
	$parametersExample = ''
	$counter = 1
	foreach($param in $apiDetails.parameters)
	{
		$parametersDocumentation += ('.PARAMETER {0} {1}{2}{1}') -f $($param.namePS), "`n", $($param.description)
		$parametersDefinition += ('[Parameter(Mandatory = ${0}, Position = {1})] [{2}] ${3}, {4}') -f $param.mandatory.ToString().ToLower(), $counter, $param.type, $param.namePS, "`n"
		$parametersBody += ('{0} = ${1} {2}') -f $param.name, $param.namePS, "`n"
		$parametersExample += (' -{0} <{1}>') -f $param.namePS, $param.name
		
		$counter++
	}
	$parametersDocumentation = $parametersDocumentation.TrimEnd()
	$parametersDefinition = $parametersDefinition.TrimEnd().TrimEnd(',')
	$parametersBody = $parametersBody.TrimEnd()
	
	$parametersAsJson = ""
	# for POST requests, we have to convert the parameters to JSON
	if($apiDetails.method -eq "POST")
	{
		$parametersAsJson = ('{0}$parameters = $parameters | ConvertTo-Json{0}') -f "`n"
	}
	
	$docTemplate = ('
Function {0}
{{
			<#
			.SYNOPSIS
			{1}
			.DESCRIPTION
			{1}
			Official API Documentation: {2}
			{3}
			.EXAMPLE
			{0}{4}
			#>
			[CmdletBinding()]
			param
			(
			{5}
			)

			Test-Initialized

			Write-Verbose "Setting final ApiURL ..."
			$apiUrl = Get-ApiUrl -ApiEndpoint "/{6}"
			$requestMethod = "{7}"
			Write-Verbose "API Call: $requestMethod $apiUrl"

			#Set headers
			$headers = Get-RequestHeader

			Write-Verbose "Setting Parameters for API call ..."
			#Set parameters
			$parameters = @{{
			{8} 
			}}
			{9}
			$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

			return $result
}}').Trim() -f $psFunctionName, $apiDetails.description, $apiDetails.link, $parametersDocumentation, $parametersExample, $parametersDefinition, $apiDetails.endpoint, $apiDetails.method, $parametersBody, $parametersAsJson
	
	$docTemplate
}

function Get-FunctionTemplate($html, $name, $psFunctionName)
{
	$docItem = Get-DocumentationItem -html $html -name $name
	$apiDetails = Get-ApiEndpointDetails -docItem $docItem
	$functionText = Get-PSFunctionTemplateFromApiDetails -apiDetails $apiDetails -psFunctionName $psFunctionName
	
	[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

	$title = 'Function Text'
	$msg   = "$psFunctionName `n`n Please Copy&Paste the source code"

	$text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title, $functionText)
}

$documentationUri = "https://docs.databricks.com/api/latest/jobs.html"
$html = Invoke-WebRequest $documentationUri 

$functionsHtml = $html.ParsedHtml.getElementsByTagName("h2")
$functions = $functionsHtml | ForEach-Object { $_.innerText.ToString().Trim().ToLower().replace(" ", "-") } | Where-Object { $_ -ne "Data Structures" }
#$functions
$functions | ForEach-Object { Write-Host "Get-FunctionTemplate -html `$html -name ""$_"" -psFunctionName ""Get-DbJob""" }

if($false)
{ 
	# Workspace API
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Delete-WorkspaceItem"
	Get-FunctionTemplate -html $html -name "export" -psFunctionName "Export-WorkspaceItem"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Remove-WorkspaceItem"
	Get-FunctionTemplate -html $html -name "get-status" -psFunctionName "Get-WorkspaceItemDetails"
	Get-FunctionTemplate -html $html -name "import" -psFunctionName "Import-WorkspaceItem"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-WorkspaceItem"
	Get-FunctionTemplate -html $html -name "mkdirs" -psFunctionName "New-WorkspaceDirectory"
	
	
	# Jobs API
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-Job"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-Job"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Remove-Job"
	#Get-FunctionTemplate -html $html -name "get" -psFunctionName "Get-Job" # same as "list" but wit -id parameter
	Get-FunctionTemplate -html $html -name "reset" -psFunctionName "Update-Job"
	Get-FunctionTemplate -html $html -name "run-now" -psFunctionName "Start-Job"
	Get-FunctionTemplate -html $html -name "runs-submit" -psFunctionName "Start-Notebook"
	Get-FunctionTemplate -html $html -name "runs-list" -psFunctionName "Get-JobRun"
	Get-FunctionTemplate -html $html -name "runs-get" -psFunctionName "Get-JobRun"
	Get-FunctionTemplate -html $html -name "runs-export" -psFunctionName "Export-JobRun"
	Get-FunctionTemplate -html $html -name "runs-cancel" -psFunctionName "Cancel-JobRun"
	Get-FunctionTemplate -html $html -name "runs-get-output" -psFunctionName "Get-JobRunOutput"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Remove-JobRun"
	
	# Secrets API
	Get-FunctionTemplate -html $html -name "create-secret-scope" -psFunctionName "Add-SecretScope"
	Get-FunctionTemplate -html $html -name "delete-secret-scope" -psFunctionName "Remove-SecretScope"
	Get-FunctionTemplate -html $html -name "list-secret-scopes" -psFunctionName "Get-SecretScope"
	Get-FunctionTemplate -html $html -name "put-secret" -psFunctionName "Add-Secret"
	Get-FunctionTemplate -html $html -name "delete-secret" -psFunctionName "Remove-Secret"
	Get-FunctionTemplate -html $html -name "list-secrets" -psFunctionName "Get-Secret"
	Get-FunctionTemplate -html $html -name "put-secret-acl" -psFunctionName "Add-SecretScopeACL"
	Get-FunctionTemplate -html $html -name "delete-secret-acl" -psFunctionName "Remove-SecretScopeACL"
	Get-FunctionTemplate -html $html -name "get-secret-acl" -psFunctionName "Get-SecretScopeACL"
	#Get-FunctionTemplate -html $html -name "list-secret-acls" -psFunctionName "Get-SecretScopeACL"


	# Tokens API
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-ApiToken"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-ApiToken"
	Get-FunctionTemplate -html $html -name "revoke" -psFunctionName "Remove-ApiToken"
	
	# Clusters API
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-Cluster"
	Get-FunctionTemplate -html $html -name "edit" -psFunctionName "Update-Cluster"
	Get-FunctionTemplate -html $html -name "start" -psFunctionName "Start-Cluster"
	Get-FunctionTemplate -html $html -name "restart" -psFunctionName "Restart-Cluster"
	Get-FunctionTemplate -html $html -name "resize" -psFunctionName "Resize-Cluster"
	Get-FunctionTemplate -html $html -name "delete-terminate" -psFunctionName "Stop-Cluster"
	Get-FunctionTemplate -html $html -name "permanent-delete" -psFunctionName "Remove-Cluster"
	Get-FunctionTemplate -html $html -name "get" -psFunctionName "Get-Cluster"
	#Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-Cluster"
	Get-FunctionTemplate -html $html -name "pin" -psFunctionName "Pin-Cluster"
	Get-FunctionTemplate -html $html -name "unpin" -psFunctionName "Unpin-Cluster"
	Get-FunctionTemplate -html $html -name "list-node-types" -psFunctionName "Get-NodeType"
	Get-FunctionTemplate -html $html -name "list-zones" -psFunctionName "Get-Zone"
	Get-FunctionTemplate -html $html -name "spark-versions" -psFunctionName "Get-SparkVersion"
	Get-FunctionTemplate -html $html -name "events" -psFunctionName "Get-ClusterEvents"
	
	# Groups API
	Get-FunctionTemplate -html $html -name "add-member" -psFunctionName "Add-GroupMember"
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-Group"
	Get-FunctionTemplate -html $html -name "list-members" -psFunctionName "Get-GroupMember"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-Group"
	Get-FunctionTemplate -html $html -name "list-parents" -psFunctionName "Get-Membership"
	Get-FunctionTemplate -html $html -name "remove-member" -psFunctionName "Remove-GroupMember"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Remove-Group"
	
	# DBFS API
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-FSFile"
	Get-FunctionTemplate -html $html -name "add-block" -psFunctionName "Add-FSFileBlock"
	Get-FunctionTemplate -html $html -name "close" -psFunctionName "Close-FSFile"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Remove-FSFile"
	Get-FunctionTemplate -html $html -name "get-status" -psFunctionName "Get-FSItem"
	#Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-FSFile" # same ase Get-FSItem
	Get-FunctionTemplate -html $html -name "mkdirs" -psFunctionName "Add-FSDirectory"
	
	Get-FunctionTemplate -html $html -name "move" -psFunctionName "Move-FSFile"
	#Get-FunctionTemplate -html $html -name "put" -psFunctionName "Get-DbJob" # NOT IMPLEMENTED / DOES NOT APPLY TO PowerShell
	Get-FunctionTemplate -html $html -name "read" -psFunctionName "Get-FSContent"
	
	# Libraries API
	Get-FunctionTemplate -html $html -name "all-cluster-statuses" -psFunctionName "Get-ClusterLibraries"
	#Get-FunctionTemplate -html $html -name "cluster-status" -psFunctionName "Get-ClusterLibrary" # same as above
	Get-FunctionTemplate -html $html -name "install" -psFunctionName "Add-ClusterLibraries"
	Get-FunctionTemplate -html $html -name "uninstall" -psFunctionName "Remove-ClusterLibraries"
	
	
	# Instance Profiles API
	Get-FunctionTemplate -html $html -name "profiles-add" -psFunctionName "Add-InstanceProfile"
	Get-FunctionTemplate -html $html -name "profiles-list" -psFunctionName "Get-InstanceProfile"
	Get-FunctionTemplate -html $html -name "profiles-remove" -psFunctionName "Remove-InstanceProfile"
	
	#TODO
}

