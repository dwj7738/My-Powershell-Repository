function Get-SchTasks{
    Param(
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyname=$True)]
        $ComputerName = $Env:ComputerName
        )
[xml]$SchTasks = schtasks /query /XML ONE /S $ComputerName
$Tasks = $SchTasks.Tasks.Task

$Tasks | %
	{
	$TaskURI = $_ | Select -ExpandProperty RegistrationInfo | Select -ExpandProperty URI
	$Name = Split-Path $TaskURI -Leaf
	$Location = Split-Path $TaskURI -Parent
	$Principal = $_ | Select -ExpandProperty Principals | Select -ExpandProperty Principal | Select ID,UserID
	$Account = $Principal.UserID
	$ID = $Principal.ID
	New-Object PSObject -Property @
		{
		Computer = $ComputerName
		Task = $Name
		Location = $Location
		ID = $ID
		RunAsAccount = $Account
		} 	
    }

}
   