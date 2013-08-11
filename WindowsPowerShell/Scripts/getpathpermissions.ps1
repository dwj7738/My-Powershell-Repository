function Get-PathPermissions {
	 
	param ( [Parameter(Mandatory=$true)] [System.String]${Path} )
	 
	    begin {
	    $root = Get-Item $Path
	    ($root | get-acl).Access | Add-Member -MemberType NoteProperty -Name "Path" -Value $($root.fullname).ToString() -PassThru
	    }
	    process {
	    $containers = Get-ChildItem -path $Path -recurse | ? {$_.psIscontainer -eq $true}
	    if ($containers -eq $null) {break}
	        foreach ($container in $containers)
	        {
	        (Get-ACL $container.fullname).Access | ? { $_.IsInherited -eq $false } | Add-Member -MemberType NoteProperty -Name "Path" -Value $($container.fullname).ToString() -PassThru
	        }
	    }
	}
	Get-PathPermissions $args[0]