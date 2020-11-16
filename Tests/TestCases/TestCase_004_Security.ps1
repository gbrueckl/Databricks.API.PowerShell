# Set-DatabricksEnvironment is already done by the caller!
# Current Directory is set by Test-Module.ps1 to the root of this repository!
$testCaseName = $myInvocation.MyCommand.Name
Write-Information "Starting Testcase $testCaseName ..."


Write-Information "Testing Secrets API ..."
$testGroupName = "DatabricksPS_AutomatedTest_Group1"

Write-Information "Checking if SCIM Group  '$testGroupName' already exists ..."
$currentGroup = Get-DatabricksSCIMGroup | Where-Object { $_.displayName -eq $testGroupName }

if ($currentGroup) {
	# Remove-DatabricksSCIMGroup -GroupID $currentGroup.id -ErrorAction SilentlyContinue
	Write-Warning "Secret SCIM Group '$testGroupName' already exists: $currentGroup"
	Write-Warning "You can manually remove it by running: Remove-DatabricksSCIMGroup -GroupID $($currentGroup.id) -ErrorAction SilentlyContinue"

	Write-Error "Secret SCIM Group '$testGroupName' already exists in the Databricks Workspace and real data may be overwritten during the test!
	Please check the SCIM GROUP and delete it manually before running the test again."
}

try {
	Write-Information "Adding SCIM Group '$testGroupName' ..."
	$currentGroup = Add-DatabricksSCIMGroup -GroupName $testGroupName -Entitlements 'allow-cluster-create'
	
	Write-Information "Getting test user to be added ..."
	$user = Get-DatabricksSCIMUser

	if($user)
	{
		$userName = ($user[0].emails | Where-Object { $_.primary }).value
		Write-Information "Adding user '$userName' to Group '$testGroupName' ..."
		$currentGroup | Add-DatabricksGroupMember -UserName $userName

		Write-Information "Getting Memberships of User '$userName' ..."
		Get-DatabricksGroupMembership -UserName $userName

		Write-Information "Removing User '$userName' from Group '$testGroupName' ..."
		$currentGroup | Remove-DatabricksGroupMember -UserName $userName
	}
	else 
	{
		Write-Warning "No User found to be added - skipping this test!"
	}


	Write-Information "Getting test group to be added ..."
	$group = Get-DatabricksGroup | Where-Object { $_ -ne $testGroupName}

	if($group)
	{
		$groupName = $group[0]
		Write-Information "Adding group '$groupName' to Group '$testGroupName' ..."
		$currentGroup | Add-DatabricksGroupMember -GroupName $groupName

		Write-Information "Getting Memberships of User '$groupName' ..."
		Get-DatabricksGroupMembership -GroupName $groupName

		Write-Information "Removing Group '$groupName' from Group '$testGroupName' ..."
		$currentGroup | Remove-DatabricksGroupMember -GroupName $groupName
	}
	else 
	{
		Write-Warning "No User found to be added - skipping this test!"
	}


	Write-Information "Getting Service Principal to be added ..."
	$sp = Get-DatabricksSCIMServicePrincipal
	if($sp)
	{
		$spID = $sp[0].applicationId
		Write-Information "Adding Service Principal '$spID' to Group '$testGroupName' ..."
		$currentGroup | Add-DatabricksGroupMember -ServicePrincipalID $spID

		Write-Information "Getting Memberships of Service Principal '$spID' ..."
		Get-DatabricksGroupMembership -ServicePrincipalID $spID

		Write-Information "Removing Service Principal '$spID' from Group '$testGroupName' ..."
		$currentGroup | Remove-DatabricksGroupMember -ServicePrincipalID $spID
	}
	
	Remove-DatabricksSCIMGroup -GroupID $currentGroup.id

	Write-Information "S U C C E S S  -  Testcase '$testCaseName' finished successfully!"
}
catch {
	throw $_
}
finally {
	Write-Information "Starting Cleanup for testcase '$testCaseName' ..."

	$currentGroup = Get-DatabricksSCIMGroup | Where-Object { $_.displayName -eq $testGroupName }

	if($currentGroup)
	{
		Write-Information "Removing SCIM Group '$testGroupName' ..."
		Remove-DatabricksSCIMGroup -GroupID $currentGroup.id
	}
	Write-Information "Finished Cleanup for testcase '$testCaseName'!"
}



