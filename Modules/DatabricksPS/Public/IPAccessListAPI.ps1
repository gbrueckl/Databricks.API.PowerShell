Function Get-DatabricksIPAccessList {
	<#
		.SYNOPSIS
		Get an IP access list, specified by its list ID.
		.DESCRIPTION
		Get an IP access list, specified by its list ID.
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html#operation/get-lists
		.PARAMETER IPAccessListID 
		The ID of the IP Access List (optional).
		.EXAMPLE
		Get-DatabricksIPAccessList
		.EXAMPLE
		Get-DatabricksIPAccessList -IPAccessListID "b2c3970b-8cf7-4203-b37b-8f4be63fdd69"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("ip_access_list_id", "list_id")] [string] $IPAccessListID
	)
	
	begin {
		$requestMethod = "GET"
		$apiEndpoint = "/2.0/ip-access-lists"
	}
	
	process {
		if ($IPAccessListID) {
			Write-Verbose "IPAccessListID specified ($IPAccessListID)- using Get-API instead of List-API..."
			$apiEndpoint = "/2.0/ip-access-lists/$IPAccessListID"
		}

		#Set parameters
		Write-Verbose "Building Body/Parameters for final API call ..."
		$parameters = @{ }

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		if ($IPAccessListID) {
			# if a IPAccessListID was specified, we return the result as it is
			return $result
		}
		else {
			# if no IPAccessListID was specified, we return the ip_access_lists as an array
			return $result.ip_access_lists
		}
	}
}

Function Add-DatabricksIPAccessList {
	<#
		.SYNOPSIS
		Add an IP access list for this workspace. A list can be an allow list or a block list. See the top of this file for a description of how the server treats allow lists and block lists at run time.
		.DESCRIPTION
		Add an IP access list for this workspace. A list can be an allow list or a block list. See the top of this file for a description of how the server treats allow lists and block lists at run time.
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html#operation/add-list
		.PARAMETER Label
		Label for the IP access list. This cannot be empty.
		.PARAMETER ListType 
		Type of IP access list. Valid values are as follows and are case-sensitive: 
		ALLOW — An allow list. Include this IP or range.
		BLOCK — A block list. Exclude this IP or range. IP addresses in the block list are excluded even if they are included in an allow list.
		.PARAMETER IPAddresses 
		Array of IP addresses or CIDR values to be added to the IP access list.
		.EXAMPLE
		Add-DatabricksIPAccessList -Label "MyList1" -ListType "BLOCK" -IPAddresses @("123.123.123.123")
		.EXAMPLE
		Add-DatabricksIPAccessList -Label "MyList2" -ListType "ALLOW" -IPAddresses @("123.123.123.123", "192.168.100.0/22")
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $Label,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("list_type")] [string] [ValidateSet("ALLOW", "BLOCK")] $ListType,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("ip_addresses")] [string[]] $IPAddresses
	)
	begin {
		$requestMethod = "POST"
		$apiEndpoint = "/2.0/ip-access-lists"
	}

	process {
		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			label = $Label
			list_type = $ListType
			ip_addresses = $IPAddresses
		}
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.ip_access_list
	}
}


Function Remove-DatabricksIPAccessList {
	<#
		.SYNOPSIS
		Delete an IP access list, specified by its list ID.
		.DESCRIPTION
		Delete an IP access list, specified by its list ID.
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html#/paths/~1ip-access-lists~1{ip_access_list_id}/delete
		.PARAMETER IPAccessListID 
		The ID for the corresponding IP access list to delete.
		.EXAMPLE
		Remove-DatabricksIPAccessList -IPAccessListID "b2c3970b-8cf7-4203-b37b-8f4be63fdd69"
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("ip_access_list_id", "list_id")] [string] $IPAccessListID
	)
	
	begin {
		$requestMethod = "DELETE"
	}
	
	process {
		$apiEndpoint = "/2.0/ip-access-lists/$IPAccessListID"

		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint
    
		return $result
	}
}


Function Update-DatabricksIPAccessList {
	<#
		.SYNOPSIS
		Modify an existing IP access list, specified by its ID. A list can include allow lists and block lists. See the top of this file for a description of how the server treats allow lists and block lists at run time.
		.DESCRIPTION
		Modify an existing IP access list, specified by its ID. A list can include allow lists and block lists. See the top of this file for a description of how the server treats allow lists and block lists at run time.
		Official API Documentation: https://docs.databricks.com/dev-tools/api/latest/ip-access-list.html#operation/update-list
		.PARAMETER IPAccessListID 
		The ID for the corresponding IP access list to update.
		.PARAMETER Label
		Label for the IP access list. 
		.PARAMETER ListType 
		Type of IP access list. Valid values are as follows and are case-sensitive: 
		ALLOW — An allow list. Include this IP or range.
		BLOCK — A block list. Exclude this IP or range. IP addresses in the block list are excluded even if they are included in an allow list.
		.PARAMETER IPAddresses 
		Array of IP addresses or CIDR values to be added to the IP access list.
		.EXAMPLE
		Update-DatabricksIPAccessList -IPAccessListID "b2c3970b-8cf7-4203-b37b-8f4be63fdd69" -Label "MyNewList" -ListType "ALLOW"
		.EXAMPLE
		Update-DatabricksIPAccessList -IPAccessListID "b2c3970b-8cf7-4203-b37b-8f4be63fdd69" -IPAddresses @("123.123.123.123", "192.168.100.0/22")
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [Alias("ip_access_list_id", "list_id")] [string] $IPAccessListID,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [string] $Label,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("list_type")] [string] [ValidateSet("ALLOW", "BLOCK")] $ListType,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [Alias("ip_addresses")] [string[]] $IPAddresses,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)] [bool] $Enabled
	)
	begin {
		$requestMethod = "PATCH"
	}

	process {
		$apiEndpoint = "/2.0/ip-access-lists/$IPAccessListID"

		Write-Verbose "Building Body/Parameters for final API call ..."
		#Set parameters
		$parameters = @{
			list_id = $IPAccessListID
		}

		$parameters | Add-Property -Name "label" -Value $Label
		$parameters | Add-Property -Name "list_type" -Value $ListType
		$parameters | Add-Property -Name "ip_addresses" -Value $IPAddresses
		$parameters | Add-Property -Name "enabled" -Value $Enabled
	
		$result = Invoke-DatabricksApiRequest -Method $requestMethod -EndPoint $apiEndpoint -Body $parameters

		return $result.ip_access_list
	}
}