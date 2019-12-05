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
  Write-Verbose "Databricks environment already initialized!"
}

Function Clear-ScriptVariables
{
  $script:dbAccessToken = $null
  $script:dbApiRootUrl = $null
  $script:dbApiFullUrl = $null
  $script:dbCloudProvider = $null
  $script:dbInitialized = $false
  $script:dbAuthenticationProvider = $null
  $script:dbAuthenticationHeader = $null
  $script:dbUseCachedDynamicParamValues = $null
  $script:dbCachedDynamicParamTimeout = $null
  $script:dbCachedDynamicParamValues = @{}
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
	
  $headers = $script:dbAuthenticationHeader
  $headers["Content-Type"] = "application/json"
	
  return $headers
  <#
      switch($script:dbAuthenticationProvider)
      {
      "DatabricksApi" {	
      return @{
        "Authorization" = "Bearer $script:dbAccessToken"
        "Content-Type" = "application/json"
      }
      }
      }
  #>
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
    [Parameter(Mandatory = $false, Position = 5)] [object] $NullValue = $null,
    [Parameter(Mandatory = $false, Position = 6)] [switch] $Force
  )
	
  if($Value -eq $null -or $Value -eq $NullValue)
  {
    Write-Verbose "Found a null-Value to add as $Name ..."
    if($AllowEmptyValue)
    {
      Write-Verbose "Adding null-value  ..."
      $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
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
      $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
    }
  }
  elseif($Value.GetType().Name -eq 'Hashtable') # hashtable
  {
    Write-Verbose "Found a Hashtable-Property to add as $Name ..."
    if($Value.Count -gt 0 -or $AllowEmptyValue)
    {
      $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
    }
  }
  elseif($Value.GetType().Name -eq 'String') # String
  {
    Write-Verbose "Found a String-Property to add as $Name ..."
    if(-not [string]::IsNullOrEmpty($Value) -or $AllowEmptyValue)
    {
      $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
    }
  }
  elseif($Value.GetType().Name -eq 'Boolean') # Boolean
  {
    Write-Verbose "Found a Boolean-Property to add as $Name ..."

    $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value.ToString().ToLower() -Force:$Force
  }
  else
  {
    Write-Verbose "Found a $($Value.GetType().Name)-Property to add as $Name ..."

    $Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
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
    throw "Property $Name already exists! Use -Force parameter to overwrite it!"	
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
    [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
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



function ConvertTo-Hashtable
{
  <# 
      .SYNOPSIS 
      Converts a PowerShell object to a generic hashtable 
      .DESCRIPTION 
      Converts a PowerShell object to a generic hashtable 
      .PARAMETER InputObject
      The object to convert to a hashtable
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $InputObject
  )

  process
  {
    if ($InputObject -is [Hashtable]) { return $InputObject }
		
    if ($null -eq $InputObject) { return $null }

    if (($InputObject -is [System.Collections.IEnumerable]) -and $InputObject -isnot [string])
    {
      $collection = @()
			
      foreach ($object in $InputObject) 
      { 
        $collection += ConvertTo-Hashtable $object 
      }

      return $collection
    }
    elseif ($InputObject -is [PSCustomObject])
    {
      $hash = @{}

      foreach ($property in $InputObject.PSObject.Properties)
      {
        $hash[$property.Name] = ConvertTo-Hashtable $property.Value
      }

      return $hash
    }
    else
    {
      return $InputObject
    }
  }
}

function ConvertTo-PSObject 
{
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] [hashtable] $InputObject, 
    [Parameter()] [bool] $Recursive = $true
  )

  process
  {
    $output = New-Object PSCustomObject
    foreach ($k in $InputObject.Keys)
    {
      if ($InputObject[$k] -is [hashtable] -and $Recursive)
      {
        $value = ConvertTo-PSObject -InputObject $InputObject[$k] -Recursive $Recursive
      }
      else
      {
        $value = $InputObject[$k] 
      }
		
      Add-Member -InputObject $output -MemberType NoteProperty -Name $k -Value $value 
    }
    return [PSCustomObject]$output
  }
}
	
# TRY/CATCH with proper Error message on APIs
#try { Invoke-RestMethod -Uri $Uri -Headers $Headers }
#catch { ([System.IO.StreamReader]$_.Exception.Response.GetResponseStream()).ReadToEnd() }

Function New-DynamicParam {
  <#
      .SYNOPSIS
        Helper function to simplify creating dynamic parameters
    
      .DESCRIPTION
        Helper function to simplify creating dynamic parameters
        Example use cases:
            Include parameters only if your environment dictates it
            Include parameters depending on the value of a user-specified parameter
            Provide tab completion and intellisense for parameters, depending on the environment
        Please keep in mind that all dynamic parameters you create will not have corresponding variables created.
           One of the examples illustrates a generic method for populating appropriate variables from dynamic parameters
           Alternatively, manually reference $PSBoundParameters for the dynamic parameter value
      .NOTES
        Originally found at https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DynamicParam.ps1
        Credit to http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/
            Added logic to make option set optional
            Added logic to add RuntimeDefinedParameter to existing DPDictionary
            Added a little comment based help
        Credit to BM for alias and type parameters and their handling
      .PARAMETER Name
        Name of the dynamic parameter
      .PARAMETER Type
        Type for the dynamic parameter.  Default is string
      .PARAMETER Alias
        If specified, one or more aliases to assign to the dynamic parameter
      .PARAMETER ValidateSet
        If specified, set the ValidateSet attribute of this dynamic parameter
      .PARAMETER ValidateScript
        If specified, set the ValidateScript attribute of this dynamic parameter
      .PARAMETER Mandatory
        If specified, set the Mandatory attribute for this dynamic parameter
      .PARAMETER ParameterSetName
        If specified, set the ParameterSet attribute for this dynamic parameter
      .PARAMETER Position
        If specified, set the Position attribute for this dynamic parameter
      .PARAMETER ValueFromPipelineByPropertyName
        If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter
      .PARAMETER ValueFromPipeline
        If specified, set the ValueFromPipeline attribute for this dynamic parameter
      .PARAMETER HelpMessage
        If specified, set the HelpMessage for this dynamic parameter
    
      .PARAMETER DPDictionary
        If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary (appropriate for multiple dynamic parameters)
        If not specified, create and return a RuntimeDefinedParameterDictionary (appropriate for a single dynamic parameter)
        See final example for illustration
      .EXAMPLE
        
        function Show-Free
        {
            [CmdletBinding()]
            Param()
            DynamicParam {
                $options = @( gwmi win32_volume | %{$_.driveletter} | sort )
                New-DynamicParam -Name Drive -ValidateSet $options -Position 0 -Mandatory
            }
            begin{
                #have to manually populate
                $drive = $PSBoundParameters.drive
            }
            process{
                $vol = gwmi win32_volume -Filter "driveletter='$drive'"
                "{0:N2}% free on {1}" -f ($vol.Capacity / $vol.FreeSpace),$drive
            }
        } #Show-Free
        Show-Free -Drive <tab>
      # This example illustrates the use of New-DynamicParam to create a single dynamic parameter
      # The Drive parameter ValidateSet populates with all available volumes on the computer for handy tab completion / intellisense
      .EXAMPLE
      # I found many cases where I needed to add more than one dynamic parameter
      # The DPDictionary parameter lets you specify an existing dictionary
      # The block of code in the Begin block loops through bound parameters and defines variables if they don't exist
        Function Test-DynPar{
            [cmdletbinding()]
            param(
                [string[]]$x = $Null
            )
            DynamicParam
            {
                #Create the RuntimeDefinedParameterDictionary
                $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
                New-DynamicParam -Name AlwaysParam -ValidateSet @( gwmi win32_volume | %{$_.driveletter} | sort ) -DPDictionary $Dictionary
                #Add dynamic parameters to $dictionary
                if($x -eq 1)
                {
                    New-DynamicParam -Name X1Param1 -ValidateSet 1,2 -mandatory -DPDictionary $Dictionary
                    New-DynamicParam -Name X1Param2 -DPDictionary $Dictionary
                    New-DynamicParam -Name X3Param3 -DPDictionary $Dictionary -Type DateTime
                }
                else
                {
                    New-DynamicParam -Name OtherParam1 -Mandatory -DPDictionary $Dictionary
                    New-DynamicParam -Name OtherParam2 -DPDictionary $Dictionary
                    New-DynamicParam -Name OtherParam3 -DPDictionary $Dictionary -Type DateTime
                }
        
                #return RuntimeDefinedParameterDictionary
                $Dictionary
            }
            Begin
            {
                #This standard block of code loops through bound parameters...
                #If no corresponding variable exists, one is created
                    #Get common parameters, pick out bound parameters not in that set
                    Function _temp { [cmdletbinding()] param() }
                    $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command _temp | select -ExpandProperty parameters).Keys -notcontains $_}
                    foreach($param in $BoundKeys)
                    {
                        if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) )
                        {
                            New-Variable -Name $Param -Value $PSBoundParameters.$param
                            Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
                        }
                    }
                #Appropriate variables should now be defined and accessible
                    Get-Variable -scope 0
            }
        }
      # This example illustrates the creation of many dynamic parameters using New-DynamicParam
        # You must create a RuntimeDefinedParameterDictionary object ($dictionary here)
        # To each New-DynamicParam call, add the -DPDictionary parameter pointing to this RuntimeDefinedParameterDictionary
        # At the end of the DynamicParam block, return the RuntimeDefinedParameterDictionary
        # Initialize all bound parameters using the provided block or similar code
      .FUNCTIONALITY
        PowerShell Language
  #>
  param(
    [string] $Name, 
    [System.Type] $Type = [string],
    [string[]] $Alias = @(),
    [string[]] $ValidateSet,
    [scriptblock]$validateScript,
    [switch] $Mandatory,
    [string] $ParameterSetName="__AllParameterSets",
    [int] $Position,
    [switch] $ValueFromPipelineByPropertyName,
    [switch]$ValueFromPipeline,
    [string] $HelpMessage,
    [validatescript({
          if(-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) )
          {
            Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
          }
          $True
    })]
    $DPDictionary = $false
 
  )
    #Create attribute object, add attributes, add to collection   
    $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
    $ParamAttr.ParameterSetName = $ParameterSetName
    if($mandatory)
    {
        $ParamAttr.Mandatory = $True
    }
    if($Position -ne $null)
    {
        $ParamAttr.Position=$Position
    }
    if($ValueFromPipelineByPropertyName)
    {
        $ParamAttr.ValueFromPipelineByPropertyName = $True
    }
    if ($ValueFromPipeline)
    {
        $ParamAttr.ValueFromPipeline = $True
    }
    if($HelpMessage)
    {
        $ParamAttr.HelpMessage = $HelpMessage
    }
         
    $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
    $AttributeCollection.Add($ParamAttr)
    
    #param validation set if specified
    if($ValidateSet)
    {
        $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
        $AttributeCollection.Add($ParamOptions)
    }
    if ($validateScript)
    {
        $paramScript = New-Object -TypeName System.Management.Automation.ValidateScriptAttribute -ArgumentList $validateScript
        $AttributeCollection.Add($paramScript)
    }

    #Aliases if specified
    if($Alias.count -gt 0) {
        $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList $Alias
        $AttributeCollection.Add($ParamAlias)
    }

 
    #Create the dynamic parameter
    $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)
    
    #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
    if($DPDictionary)
    {
        $DPDictionary.Add($Name, $Parameter)
    }
    else
    {
      $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
      $Dictionary.Add($Name, $Parameter)
      $Dictionary
    }
}

Function Get-DynamicParamValues {
  Param (
    [parameter(Mandatory = $true)] [scriptblock] $Command
  )
  Process {
    if(-not $script:dbInitialized)
    {
      return $null
    }
    
    $commandText = $Command.ToString()
    $commandTextGeneric = (($commandText -split 'Get-')[1] -split ' ')[0].Trim()
    
    # some parameter values are dynamic but do not change
    $hasFixedValues = $commandTextGeneric -in ('DatabricksNodeType', 'DatabricksSparkVersion')
    
    if($script:dbDynamicParameterCacheTimeout -gt 0 -or $hasFixedValues)
    {
      Write-Verbose "Trying to using cached Dynamic Parameter Values"
      if($script:dbCachedDynamicParamValues[$commandTextGeneric])
      {
        Write-Verbose "Cached Dynamic Parameter Values found for '$commandTextGeneric'!"
        $cache = $script:dbCachedDynamicParamValues[$commandTextGeneric]
        
        $seconds = (New-TimeSpan -Start $cache.lastRefresh -End (Get-Date)).Seconds
        
        if($seconds -lt $script:dbDynamicParameterCacheTimeout -or $hasFixedValues)
        {
          Write-Verbose "Returning Cached Dynamic Parameter Values!"
          return $cache.cachedValues
        }
      }
    }
    
    Write-Verbose "Caching not enabled, Cached Value not found or timed out! Evaluating command, caching and returning results ..."
    $values = Invoke-Command -ScriptBlock $Command
    $cache = @{
      "cachedValues" = $values
      "lastRefresh" = Get-Date
    }
    $script:dbCachedDynamicParamValues[$CommandTextGeneric] = $cache
    return $values
  } 
}