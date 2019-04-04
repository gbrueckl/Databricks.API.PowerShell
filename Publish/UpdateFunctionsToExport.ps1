# if executed from PowerShell ISE
if ($psise) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent
}
else {
	$rootPath = (Get-Item $PSScriptRoot).Parent.FullName
}

$moduleName = $ModuleName = (Get-ChildItem "$rootPath\Modules")[0].Name
$psdFilePath = "$rootPath\Modules\$moduleName\$moduleName.psd1"

$PublicFunctions = @( Get-ChildItem -Path "$rootPath\Modules\$moduleName\Public\*.ps1" -ErrorAction SilentlyContinue )
$PublicFunctions = $PublicFunctions | Where-Object { $_.Name -inotlike "*-PREVIEW.ps1" }

$exportedCmdlets = @()
foreach($import in $PublicFunctions)
{
	Write-Information "Reading available functions from $($import.FullName) ..."
	$content = Get-Content $import.FullName
	# find all functions - search for "Function" or "function" followed by some whitespaces and the function name
	# function name has to contain a "-"
	$regEx = '[Ff]unction\s+(\S+\-\S+)\s'
	$matches = [regex]::Matches($content, $regEx)
	
	Write-Information "$($matches.Count) functions found! Adding them to list ..."
	$matches | ForEach-Object { 
		$exportedCmdlets += $_.Groups[1].Value
	}
}

$psdContent = Get-Content $psdFilePath -Raw

$cmdletPrefix = ''
# find "DefaultCommandPrefix"
$regEx = "DefaultCommandPrefix\s*=\s*[`"']{1}(\S*)[`"']{1}" # use 3 groups of which the second is replaced using Regex-Replace
$matches = [regex]::Matches($psdContent, $regEx)
if($matches.Groups[1])
{
	$cmdletPrefix = $matches.Groups[1].Value
	Write-Information "DefaultCommandPrefix: $cmdletPrefix"
}

# find "FunctionsToExport" and replace them with currently existing functions
$regEx = '(FunctionsToExport\s*=\s*@\()([^\)]*)(\))' # use 3 groups of which the second is replaced using Regex-Replace
$matches = [regex]::Matches($psdContent, $regEx)

#$cmdletsToExport = "`n'" + ($exportedCmdlets -join "', `n'").Replace('-', "-$cmdletPrefix") + "'`n"
$cmdletsToExport = "`n'" + ($exportedCmdlets -join "', `n'") + "'`n"

$newPsdContent = [regex]::Replace($psdContent, $regEx, '$1' + $cmdletsToExport + '$3')

Write-Information "Writing updated Content to $psdFilePath ..."
$newPsdContent | Out-File "$psdFilePath"

