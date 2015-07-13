#This sample is provided as is and is not meant for use on a 
#production environment. It is provided only for illustrative 
#purposes. The end user must test and modify the sample to suit 
#their target environment.
#
#Microsoft can make no representation concerning the content of 
#this sample. Microsoft is providing this information only as a 
#convenience to you. This is to inform you that Microsoft has not 
#tested the sample and therefore cannot make any representations 
#regarding the quality, safety, or suitability of any code or 
#information found here.

$updateServer = "localhost"
$useSecureConnection = $False
$portNumber = 8530

Add-Type -Path "C:\Program Files\Update Services\Api\Microsoft.UpdateServices.Administration.dll"
$AdminProxy = New-Object -TypeName Microsoft.UpdateServices.Administration.AdminProxy
$WSUSServer = $AdminProxy.GetRemoteUpdateServerInstance($updateServer,$useSecureConnection,$portNumber)
$WSUSServer.PreferredCulture = "en"

$ComputerGroup = $WSUSServer.GetComputerTargetGroups() | ForEach-Object -Process {if ($_.Name -eq $targetComputerGroup) {$_}}

$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$UpdateScope.ApprovedStates = "Any"
$Approvals = $WSUSServer.GetUpdateApprovals($UpdateScope)

"ComputerGroupName`tUpdateTitle`tUpdateGUID`tupdateArticleId"

foreach ($Approval in $Approvals)
{
	$ComputerGroup = $WSUSServer.GetComputerTargetGroup($Approval.ComputerTargetGroupId)
	$Update = $WSUSServer.GetUpdate($Approval.UpdateId)
	
	$ComputerGroup.Name+"`t"+$Update.Title+"`t"+$Update.Id.UpdateId+"`t"+$Update.KnowledgeBaseArticles[0]
	
}
