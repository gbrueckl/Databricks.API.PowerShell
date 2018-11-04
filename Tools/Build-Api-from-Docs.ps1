﻿function Get-DocumentationItem($html, $name)
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
			$apiUrl = Get-DbApiUrl -ApiEndpoint "/{6}"
			$requestMethod = "{7}"
			Write-Verbose "API Call: $requestMethod $apiUrl"

			#Set headers
			$headers = Get-DbRequestHeader

			Write-Verbose "Setting Parameters for API call ..."
			#Set parameters
			$parameters = @{{
			{8} 
			}}
			{9}
			$result = Invoke-RestMethod -Uri $apiUrl -Method $requestMethod -Headers $headers -Body $parameters

			return $result
	}}') -f $psFunctionName, $apiDetails.description, $apiDetails.link, $parametersDocumentation, $parametersExample, $parametersDefinition, $apiDetails.endpoint, $apiDetails.method, $parametersBody, $parametersAsJson
	
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

$documentationUri = "https://docs.databricks.com/api/latest/tokens.html"
$html = Invoke-WebRequest $documentationUri 

$functionsHtml = $html.ParsedHtml.getElementsByTagName("h2")
$functions = $functionsHtml | ForEach-Object { $_.innerText.ToString().Trim().ToLower().replace(" ", "-") } | Where-Object { $_ -ne "Data Structures" }
#$functions
$functions | ForEach-Object { Write-Host "Get-FunctionTemplate -html `$html -name ""$_"" -psFunctionName ""Get-DbJob""" }

if($false)
{ 
	# Workspace API
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Delete-DbWorkspaceItem"
	Get-FunctionTemplate -html $html -name "export" -psFunctionName "Export-DbWorkspaceItem"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Delete-DbWorkspaceItem"
	Get-FunctionTemplate -html $html -name "get-status" -psFunctionName "Get-DbWorkspaceItemDetails"
	Get-FunctionTemplate -html $html -name "import" -psFunctionName "Import-DbWorkspaceItem"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-DbWorkspaceItem"
	Get-FunctionTemplate -html $html -name "mkdirs" -psFunctionName "New-DbWorkspaceDirectory"
	
	
	# Jobs API
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-DbJob"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Delete-DbJob"
	#Get-FunctionTemplate -html $html -name "get" -psFunctionName "Get-Job" # same as "list" but wit -id parameter
	Get-FunctionTemplate -html $html -name "reset" -psFunctionName "Update-DbJob"
	Get-FunctionTemplate -html $html -name "run-now" -psFunctionName "Start-DbJob"
	Get-FunctionTemplate -html $html -name "runs-submit" -psFunctionName "Start-DbNotebook"
	Get-FunctionTemplate -html $html -name "runs-list" -psFunctionName "Get-DbJobRun"
	Get-FunctionTemplate -html $html -name "runs-get" -psFunctionName "Get-DbJobRun"
	Get-FunctionTemplate -html $html -name "runs-export" -psFunctionName "Export-DbJobRun"
	Get-FunctionTemplate -html $html -name "runs-cancel" -psFunctionName "Cancel-DbJobRun"
	Get-FunctionTemplate -html $html -name "runs-get-output" -psFunctionName "Get-DbJobRunOutput"
	Get-FunctionTemplate -html $html -name "delete" -psFunctionName "Delete-DbJobRun"
	
	# Secrets API
	Get-FunctionTemplate -html $html -name "create-secret-scope" -psFunctionName "Add-DbSecretScope"
	Get-FunctionTemplate -html $html -name "delete-secret-scope" -psFunctionName "Delete-DbSecretScope"
	Get-FunctionTemplate -html $html -name "list-secret-scopes" -psFunctionName "Get-DbSecretScope"
	Get-FunctionTemplate -html $html -name "put-secret" -psFunctionName "Add-DbSecret"
	Get-FunctionTemplate -html $html -name "delete-secret" -psFunctionName "Remove-DbSecret"
	Get-FunctionTemplate -html $html -name "list-secrets" -psFunctionName "Get-DbSecret"
	Get-FunctionTemplate -html $html -name "put-secret-acl" -psFunctionName "Add-DbSecretScopeACL"
	Get-FunctionTemplate -html $html -name "delete-secret-acl" -psFunctionName "Remove-DbSecretScopeACL"
	Get-FunctionTemplate -html $html -name "get-secret-acl" -psFunctionName "Get-DbSecretScopeACL"
	#Get-FunctionTemplate -html $html -name "list-secret-acls" -psFunctionName "Get-DbSecretScopeACL"


	# Tokens API
	#TODO
	Get-FunctionTemplate -html $html -name "create" -psFunctionName "Add-DbToken"
	Get-FunctionTemplate -html $html -name "list" -psFunctionName "Get-DbToken"
	Get-FunctionTemplate -html $html -name "revoke" -psFunctionName "Remove-DbJob"
}