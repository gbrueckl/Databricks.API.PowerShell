Function Test-Initialized
{
	<#
			.SYNOPSIS
			Checks if Set-DatabricksEnvironment was executed before any other command of the module.   
			.DESCRIPTION
			Checks if Set-DatabricksEnvironment was executed before any other command of the module.
			.EXAMPLE
			Test-Initialized
	#>
	[CmdletBinding()]
	param ()

	Write-Verbose "Checking if Databricks environment has been initialized yet ..."
	if($script:dbInitialized -eq $false)
	{
		Write-Error "Databricks environment has not been initialized yet! Please run Set-DatabricksEnvironment before any other cmdlet!"
	}
	Write-Verbose "Databricks environment already initialized."
}

function Join-Parts
{
	<#
			.SYNOPSIS
			Join strings with a specified separator.
			.DESCRIPTION
			Join strings with a specified separator.
			This strips out null values and any duplicate separator characters.
			See examples for clarification.
			.PARAMETER Separator
			Separator to join with
			.PARAMETER Parts
			Strings to join
			.EXAMPLE
			Join-Parts -Separator "/" this //should $Null /work/ /well
			# Output: this/should/work/well
			.EXAMPLE
			Join-Parts -Parts http://this.com, should, /work/, /wel
			# Output: http://this.com/should/work/wel
			.EXAMPLE
			Join-Parts -Separator "?" this ?should work ???well
			# Output: this?should?work?well
			.EXAMPLE
			$CouldBeOneOrMore = @( "JustOne" )
			Join-Parts -Separator ? -Parts CouldBeOneOrMore
			# Output JustOne
			# If you have an arbitrary count of parts coming in,
			# Unnecessary separators will not be added
			.NOTES
			Credit to Rob C. and Michael S. from this post:
			http://stackoverflow.com/questions/9593535/best-way-to-join-parts-with-a-separator-in-powershell
    
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Separator, 
		[Parameter(Mandatory = $false, Position = 2, ValueFromRemainingArguments=$true)] [string[]]$Parts = $null
	)

	return ( $Parts | Where-Object { $_ } | Foreach-Object { ( [string]$_ ).trim($Separator) } | Where-Object { $_ } ) -join $Separator
}

Function Get-DbRequestHeader
{
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-DbRequestHeader
	#>
	[CmdletBinding()]
	param ()

	Write-Verbose "Getting Headers for Databricks API call ..."
	return @{
		Authorization = "Bearer $script:dbAccessToken"
		"Content-Type" = "application/json"
	}
}

Function Get-DbApiUrl
{
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-DbRequestHeader
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1)] [string] $ApiEndpoint
	)

	Write-Verbose "Getting Headers for Databricks API call ..."
	$result = Join-Parts -Separator "/" -Parts $script:dbApiRootUrl, $ApiEndpoint
	
	return $result
}

Function Add-Property
{
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-DbRequestHeader
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [hashtable] $Hashtable,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Name,
		[Parameter(Mandatory = $true, Position = 3)] [object][AllowNull()] $Value,
		[Parameter(Mandatory = $false, Position = 4)] [bool] $AllowEmptyValue = $false,
		[Parameter(Mandatory = $false, Position = 5)] [object] $NullValue = $null
	)
	
	if($Value -eq $null -or $Value -eq $NullValue)
	{
		Write-Verbose "Found a null-Value to add ..."
		if($AllowEmptyValue)
		{
			Write-Verbose "Adding null-value  ..."
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
		else
		{
			Write-Verbose "null-value is omitted."
			# do nothing as we do not add Empty values
		}
	}
	elseif($Value.GetType().Name -eq 'Object[]') # array
	{
		Write-Verbose "Found an Array to add ..."
		if($Value.Count -gt 0 -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'Hashtable') # hashtable
	{
		Write-Verbose "Found a Hashtable to add ..."
		if($Value.Count -gt 0 -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'String') # String
	{
		Write-Verbose "Found a String to add ..."
		if(-not [string]::IsNullOrEmpty($Value) -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'Boolean') # Boolean
	{
		Write-Verbose "Found a Boolean to add ..."

		$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value.ToString().ToLower()
	}
	else
	{
		Write-Verbose "Found a $($Value.GetType().Name) to add ..."

		$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
	}
}

Function Add-PropertyIfNotExists
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [hashtable] $Hashtable,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Name,
		[Parameter(Mandatory = $true, Position = 3)][AllowNull()] [object] $Value,
		[Parameter(Mandatory = $false, Position = 4)] [switch] $Force
	)
	
	# if the property does not exist or -Force is specified, we set/overwrite the value
	if(($Hashtable.Keys -notcontains $Name) -or $Force)
	{
		$Hashtable[$Name] = $Value
	}
	else
	{
		raise "Property $Name already exists! Use -Force parameter to overwrite it!"	
	}
}