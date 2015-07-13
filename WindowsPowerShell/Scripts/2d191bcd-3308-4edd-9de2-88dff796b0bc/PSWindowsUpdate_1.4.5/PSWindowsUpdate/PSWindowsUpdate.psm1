function Test-ElevatedShell
{
	$user = [Security.Principal.WindowsIdentity]::GetCurrent()
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


if(!(Test-ElevatedShell))
{

$warning=@"
	To run some commands exposed by this module on Windows Vista, Windows Server 2008, and later versions of Windows, you must start an elevated Windows PowerShell console.
"@

	Write-Warning $warning	
}

Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }

