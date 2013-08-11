function Test-ElevatedShell
{
	$user = [Security.Principal.WindowsIdentity]::GetCurrent()
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


if(!(Test-ElevatedShell))
{

$warning=@"
	To run commands exposed by this module on Windows Vista, Windows Server 2008, and later versions of Windows,
	you must start an elevated Windows PowerShell console. You must have Administrator privligies on the remote
	computers and the remote registry service has to be running.
"@

	Write-Warning $warning	
	Exit
}

# dot-source all function files
Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }

# Export all commands except for Test-ElevatedShell
Export-ModuleMember –Function @(Get-Command –Module $ExecutionContext.SessionState.Module | Where-Object {$_.Name -ne "Test-ElevatedShell"})

