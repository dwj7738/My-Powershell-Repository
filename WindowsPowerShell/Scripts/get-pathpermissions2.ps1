$ErrorActionPreference = "SilentlyContinue"
function Get-PathPermissions2 
{

	param ( [Parameter(Mandatory=$true)] [System.String]${Path} )

	begin {
		$root = Get-Item -LiteralPath $Path
		(Get-Item -LiteralPath $root).GetAccessControl().Access | Add-Member -MemberType NoteProperty -Name “Path” -Value $($root.fullname).ToString() -PassThru -Force
		}
	process {
		$containers = Get-ChildItem -path $Path -recurse | ? {$_.psIscontainer -eq $true}
		if ($containers -eq $null) {break}
		foreach ($container in $containers)
			{
			(Get-Item -LiteralPath $container.fullname).GetAccessControl().Access | ? { $_.IsInherited -eq $false } | Add-Member -MemberType NoteProperty -Name “Path” -Value $($container.fullname).ToString() -PassThru -Force
			}
		}
}
Get-PathPermissions2 $args[0]