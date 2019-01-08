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

Function Get-RequestHeader
{
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-RequestHeader
	#>
	[CmdletBinding()]
	param ()

	Write-Verbose "Getting Headers for Databricks API call ..."
	return @{
		Authorization = "Bearer $script:dbAccessToken"
		"Content-Type" = "application/json"
	}
}

Function Get-ApiUrl
{
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-ApiUrl -ApiEndPoint "/2.0/secrets/scopes/list"
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
		Write-Verbose "Found a null-Value to add as $Name ..."
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
		Write-Verbose "Found an Array-Property to add as $Name ..."
		if($Value.Count -gt 0 -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'Hashtable') # hashtable
	{
		Write-Verbose "Found a Hashtable-Property to add as $Name ..."
		if($Value.Count -gt 0 -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'String') # String
	{
		Write-Verbose "Found a String-Property to add as $Name ..."
		if(-not [string]::IsNullOrEmpty($Value) -or $AllowEmptyValue)
		{
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value
		}
	}
	elseif($Value.GetType().Name -eq 'Boolean') # Boolean
	{
		Write-Verbose "Found a Boolean-Property to add as $Name ..."

		$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value.ToString().ToLower()
	}
	else
	{
		Write-Verbose "Found a $($Value.GetType().Name)-Property to add as $Name ..."

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


# Original Code from https://www.powershellgallery.com/packages/Carbon/2.1.0/Content/Functions%5CConvertTo-Base64.ps1
# Copied into here to avoid unnecessary dependencies
function ConvertTo-Base64
{
	<# 
			.SYNOPSIS 
			Converts a value to base-64 encoding.   
			.DESCRIPTION 
			For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process. 
			You're actually allowed to pass in `$null` and an empty string. If you do, you'll get `$null` and an empty string back. 
			.PARAMETER Value
			The value to encode as Base64 string. Also allows pipelined input!
			.PARAMETER Encoding
			The encoding to use to convert the Base64 bytes to a string. Default is [Text.Encoding]::UTF8
			.LINK 
			ConvertFrom-Base64 
			.EXAMPLE 
			ConvertTo-Base64 -Value 'Encode me, please!' 
			Encodes `Encode me, please!` into a base-64 string. 
			.EXAMPLE 
			ConvertTo-Base64 -Value 'Encode me, please!' -Encoding ([Text.Encoding]::ASCII) 
			Shows how to specify a custom encoding in case your string isn't in Unicode text encoding. 
			.EXAMPLE 
			'Encode me!' | ConvertTo-Base64 
			Converts `Encode me!` into a base-64 string. 
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string[]]
		# The value to base-64 encoding.
		$Value,
        
		[Text.Encoding] $Encoding = ([Text.Encoding]::UTF8)
	)
    
	begin
	{
		#Set-StrictMode -Version 'Latest'

		#Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState    
	}

	process
	{
		$Value | ForEach-Object {
			if( $_ -eq $null )
			{
				return $null
			}
            
			$bytes = $Encoding.GetBytes($_)
			[Convert]::ToBase64String($bytes)
		}
	}
}

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Original Code from https://www.powershellgallery.com/packages/Carbon/2.1.0/Content/Functions%5CConvertFrom-Base64.ps1
# Copied into here to avoid unnecessary dependencies
function ConvertFrom-Base64
{
	<# 
			.SYNOPSIS 
			Converts a base-64 encoded string back into its original string. 
			.DESCRIPTION 
			For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process. 
			You're actually allowed to pass in `$null` and an empty string. If you do, you'll get `$null` and an empty string back. 
			.PARAMETER Value
			The Base64 value to decode to a string. Also allows pipelined input!
			.PARAMETER Encoding
			The encoding to use to convert the Base64 bytes to a string. Default is [Text.Encoding]::UTF8
			.LINK 
			ConvertTo-Base64 
			.EXAMPLE 
			ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh' 
			Decodes `RW5jb2RlIG1lLCBwbGVhc2Uh` back into its original string. 
			.EXAMPLE 
			ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh' -Encoding ([Text.Encoding]::ASCII) 
			Shows how to specify a custom encoding in case your string isn't in Unicode text encoding. 
			.EXAMPLE 
			'RW5jb2RlIG1lIQ==' | ConvertTo-Base64 
			Shows how you can pipeline input into `ConvertFrom-Base64`. 
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string[]]
		# The base-64 string to convert.
		$Value,
        
		[Text.Encoding]
		# The encoding to use. Default is Unicode.
		$Encoding = ([Text.Encoding]::UTF8)
	)
    
	begin
	{
		#Set-StrictMode -Version 'Latest'

		#Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
	}

	process
	{
		$Value | ForEach-Object {
			if( $_ -eq $null )
			{
				return $null
			}
            
			$bytes = [Convert]::FromBase64String($_)
			$Encoding.GetString($bytes)
		}
	}
}


# TRY/CATCH with proper Error message on APIs
#try { Invoke-RestMethod -Uri $Uri -Headers $Headers }
#catch { ([System.IO.StreamReader]$_.Exception.Response.GetResponseStream()).ReadToEnd() }
