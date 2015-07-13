<#
The sample scripts are not supported under any Microsoft standard support 
program or service. The sample scripts are provided AS IS without warranty  
of any kind. Microsoft further disclaims all implied warranties including,  
without limitation, any implied warranties of merchantability or of fitness for 
a particular purpose. The entire risk arising out of the use or performance of  
the sample scripts and documentation remains with you. In no event shall 
Microsoft, its authors, or anyone else involved in the creation, production, or 
delivery of the scripts be liable for any damages whatsoever (including, 
without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use 
of or inability to use the sample scripts or documentation, even if Microsoft 
has been advised of the possibility of such damages.
#> 


Function Uninstall-OSCHotfix 
{
<#
 	.SYNOPSIS
        Uninstall-OSCHotfix is an advanced function which can be used to uninstall Windows update or hotfix in Windows 7 or higher version.
    .DESCRIPTION
        Uninstall-OSCHotfix is an advanced function which can be used to uninstall Windows update or hotfix in Windows 7 or higher version.
	.PARAMETER  ListPath
		The specified path of the text file that including HotFixIDs.
	.PARAMETER 	HotfixID
		The specified HotFix ID.
	.PARAMETER	ComputerName
		The specified computer name
	.PARAMETER	Credential
		The credential for the specified computer.
    .EXAMPLE
        C:\PS> Uninstall-OSCHotfix -HotFixID KB2830290
		
		This command shows how to uninstall the specified hotfix in local computer.
	.EXAMPLE
        C:\PS> Uninstall-OSCHotfix -ListPath "C:\HotId.txt"

			HotFixID                                                    Status
			--------                                                    ------
			KB2830290                                                   NotFound
			KB2829254                                                   Success
			KB2820330                                                   Success
			KB2807986                                                   Success

		This command shows how to uninstall the specified hotfixs by using a txt file.
	.EXAMPLE
		C:\PS> Uninstall-OSCHotfix -HotFixID KB28000333 -ComputerName WIN-D23LGM8R8E5  -Credential (Get-Credential administrator)
		
		This command shows how to uninstall the specified hotfix from a specified computer.
				
#>
	
	[cmdletbinding()]
	param
	(
		[Parameter(Mandatory = $True,Position = 0,ParameterSetName = "List")] 
	    [String]$ListPath, 
	    [Parameter(Mandatory = $True,Position = 0,ParameterSetName = "HotFixID")]
		[string]$HotfixID,
		[Parameter(Mandatory=$False,Position = 0)]
	    [Alias('CName')][String[]]$ComputerName = $env:COMPUTERNAME,
	    [Parameter(Mandatory=$False,Position = 0)]
	    [Alias('Cred')][System.Management.Automation.PSCredential]$Credential
	) 
	#Uninstall hotfix from remoted computer
	If($Credential -and $ComputerName)
	{
		#Uninstall hotfix by ID
		If($HotfixID)
		{
			$UninstallResult = UninstallHotFix $HotfixID $ComputerName $Credential
			If($UninstallResult -match "Success")
			{
				Write-Host "Uninstall $HotfixID successfully!"
			}
			ElseIf( $UninstallResult -match "NotFound")
			{
			
				Write-Host "Not found $HotfixID!"
			}
			Else
			{
				Write-Host "Failed to uninstall $HotfixID!"
			}
		}
		Else 
		{
			#Verify the path is valid
			If(Test-Path -Path $ListPath)
			{
				#Store the result to variable result.
				$result = @()
				$HotFixIDs = Get-Content -Path $ListPath
				$IDsNum = $HotFixIDs.Count
				Foreach($HotfixID in $HotFixIDs)
				{
					$intNum =  1
					Write-Progress -Activity "Uninstalling hotfix...." `
					-Status "$intNum of $IDsNum hotfixs" -PercentComplete $($intNum/$IDsNum*100)
					$UninstallResult = UninstallHotFix $HotfixID $ComputerName  $Credential
					$obj  = New-Object PSObject -Property @{
														HotFixID = $HotfixID;
														Status = $UninstallResult
														}
					$result = $result + $obj
					$intNum ++ 
				}
				$result
				
			}
			Else
			{
				Write-Warning "Invalid file path,please try again."
			}
		}
	}
	Else
	{
		If($HotfixID)
		{
			$UninstallResult =UninstallHotFix $HotfixID $ComputerName 
			If( $UninstallResult -match "Success")
			{
				Write-Host "Uninstall $HotfixID successfully!"
			}
			ElseIf($UninstallResult -match "NotFound")
			{
			
				"NotFound"
			}
			Else
			{
				"Failed"
			}
		}
		Else 
		{
			If(Test-Path -Path $ListPath)
			{
				
				$result = @()
				$HotFixIDs = Get-Content -Path $ListPath
				$IDsNum = $HotFixIDs.Count
				Foreach($HotfixID in $HotFixIDs)
				{
					$intNum =  1
					Write-Progress -Activity "Uninstalling hotfix...." `
					-Status "$intNum of $IDsNum hotfixs" -PercentComplete $($intNum/$IDsNum*100)
					$UninstallResult = UninstallHotFix $HotfixID $ComputerName 
					$obj  = New-Object PSObject -Property @{
														HotFixID = $HotfixID;
														Status = $UninstallResult
														}
					$result = $result + $obj
					$intNum ++ 
				}
				$result
				
			}
			Else
			{
				Write-Warning "Invalid file path,please try again."
			}
		}
	}
         

}

Function UninstallHotFix
{
	#Uninstall hotfix 
	Param
	(
	[Parameter(Mandatory = $True)]
	[String]$HotfixID,
	[Parameter(Mandatory = $False)]
	[String[]]$ComputerName,
	[Parameter(Mandatory = $False)]
	[System.Management.Automation.PSCredential]$Credential
	)
	If($ComputerName -and $Credential)
	{
		#Get the specified hotfix 
		$hotfix = Get-HotFix  -ComputerName $ComputerName -Credential $Credential | Where-Object {$_.HotfixID -eq $HotfixID}   
		if($hotfix) 
		{
		    $HotFixNum= $HotfixID.Replace("KB","")
			Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock `
		 	{
				$hotFixNum = $Using:HotFixNum
				Cmd /c wusa.exe /uninstall /KB:$HotFixNum /quiet /norestart
			}
		   	Do
			{
				Start-Sleep -Seconds 3
			}while(Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {Get-Process  | Where-Object {$_.name -eq "wusa"}})
			
			If(Get-HotFix -ComputerName $ComputerName  -Credential $Credential -Id $HotfixID -ErrorAction SilentlyContinue)
			{
				
				"Failed"
			}
			Else
			{
				"Success"
			}
		}
		Else 
		{            
			"NotFound"
		}    
	}
	Else
	{
		$hotfix = Get-HotFix  -ComputerName $ComputerName | Where-Object {$_.HotfixID -eq $HotfixID}   
		if($hotfix) 
		{
		    $HotFixNum= $HotfixID.Replace("KB","")
		    wusa.exe /uninstall /KB:$HotFixNum /quiet /norestart         
		   	do
			{
				Start-Sleep -Seconds 3
			}while(Get-Process | Where-Object {$_.name -eq "wusa"})
			If(Get-HotFix -Id $HotfixID -ErrorAction SilentlyContinue)
			{
				
				"Failed"
			}
			Else
			{
				"Success"
			}
		}
		Else 
		{            
			"NotFound"
		}   
	}
         	
}