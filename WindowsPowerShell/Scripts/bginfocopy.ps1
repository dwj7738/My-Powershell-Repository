<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>
$mainserver = "\\xxxxxxxxxxx\_Server_Support\support"
$ServerList = Get-Content ./testing.txt
if ($ServerList -eq $NULL)
                  {
                        Write-Output ("Could not read server list.  You  may not have permission. Exiting.")
                        return
                  }

if (Test-Path($supportpath) 
$FolderToCopy = "\\xxxxxxxxxxx\_Server_Support\support"

foreach ($Server in $ServerList)
      {
      #Echo back current server
      Write-Host "Processing Server $Server..." -ForeGroundColor "Yellow"
      if ($server -eq $NULL) {
	  	Write-Output("Server is NULL.. Exiting")
		exit	
		}
      #Remove Path if it exists on remote server
      $UNCPath = "\\$Server\c$\Support"
      Write-Host "Checking/Removing UNC Path $UNCPath"
      if (Test-Path $UNCPath)
      {
            Remove-Item -path $UNCPath -Recurse -Force
      }
      
      #Copy folder content from source to destination
      Write-Host "Copying folder $FolderToCopy to destination $UNCPath"
      Copy-Item $FolderToCopy -Destination $UNCPath -Recurse -Force
      }
      
      $FilesAndFolders = gci "c:\support" -recurse | % {$_.FullName}
foreach($FileAndFolder in $FilesAndFolders)
{
    $item = gi -literalpath $FileAndFolder 
    $acl = $item.GetAccessControl() 
    $permission = "Everyone","FullControl","Allow"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($rule)
    $item.SetAccessControl($acl)
}
{      [CmdletBinding(SupportsShouldProcess=$true)]
      param
      (
            [Parameter(Position=0, Mandatory=$false)]
            [System.String]
            $Server = "$ServerList",
            [Parameter(Position=1, Mandatory=$false)]
            [ValidateSet("ClassesRoot","CurrentConfig","CurrentUser","DynData","LocalMachine","PerformanceData","Users")]
            [System.String]
            $Hive = "LocalMachine",
            [Parameter(Position=2, Mandatory=$false, HelpMessage="Enter Registry key in format System\CurrentControlSet\Services")]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            [Parameter(Position=3, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Name = "BGInfo",
            [Parameter(Position=4, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Value = "C:\support\bginfo\Bginfo.exe C:\support\bginfo\standard.bgi /TIMER:0 /silent /NOLICPROMPT",
            [Parameter(Position=5, Mandatory=$false)]
            [ValidateSet("String","ExpandString","Binary","DWord","MultiString","QWord")]
            [System.String]
            $Type = "String",
            [Parameter(Position=6, Mandatory=$false)]
            [switch]
            $Force
      )
      
      if ($pscmdlet.ShouldProcess($Server, "Open registry $Hive"))
      {
      #Open remote registry
      try
      {
                  $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
            
      }
      catch 
      {
            Write-Error "The computer $Server is inaccessible. Please check computer name. Please ensure remote registry service is running and you have administrative access to $Server."
            return
      }
      }

      if ($pscmdlet.ShouldProcess($Server, "Check existense of $Key"))
      {
      #Open the targeted remote registry key/subkey as read/write
      $regKey = $reg.OpenSubKey($Key,$true)
            
      #Since trying to open a regkey doesn't error for non-existent key, let's sanity check
      #Create subkey if parent exists. If not, exit.
      if ($regkey -eq $null)
      {      
            Write-Warning "Specified key $Key does not exist in $Hive."
            $Key -match ".*\x5C" | Out-Null
            $parentKey = $matches[0]
            $Key -match ".*\x5C(\w*\z)" | Out-Null
            $childKey = $matches[1]

            try
            {
                  $regtemp = $reg.OpenSubKey($parentKey,$true)
            }
            catch
            {
                  Write-Error "$parentKey doesn't exist in $Hive or you don't have access to it. Exiting."
                  return
            }
            if ($regtemp -ne $null)
            {
                  Write-Output "$parentKey exists. Creating $childKey in $parentKey."
                  try
                  {
                        $regtemp.CreateSubKey($childKey) | Out-Null
                  }
                  catch 
                  {
                        Write-Error "Could not create $childKey in $parentKey. You  may not have permission. Exiting."
                        return
                  }

                  $regKey = $reg.OpenSubKey($Key,$true)
            }
            else
            {
                  Write-Error "$parentKey doesn't exist. Exiting."
                  return
            }
      }
      
      #Cleanup temp operations
      try
      {
            $regtemp.close()
            Remove-Variable $regtemp,$parentKey,$childKey
      }
      catch
      {
            #Nothing to do here. Just suppressing the error if $regtemp was null
      }
      }
      #If we got this far, we have the key, create or update values
      if ($Force)
      {
            if ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. Since -Force is in use, no confirmation needed from user"))
            {
                  $regKey.Setvalue("$Name", "$Value", "$Type")
            }
      }
      else
      {
            if ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. No -Force specified, user will be asked for confirmation"))
            {
            $message = "Value of $Name will be set to $Value. Current value `(If any`) will be replaced. Do you want to proceed?"
            $regKey.Setvalue("$Name", "$Value", "$Type")
            }
      }
      
      #Cleanup all variables
      try
      {
            $regKey.close()
            Remove-Variable $Server,$Hive,$Key,$Name,$Value,$Force,$reg,$regKey,$yes,$no,$caption,$message,$result
      }
      catch
      {
            #Suppressing the error if any variable is null
}      }