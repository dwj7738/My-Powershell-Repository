# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: PowerShell FTP Client Module
# Author: MichalGajda
# Description: The PSFTP module allow you to connect and manage the contents of ftp account. Module contain set of function to get list of items, download and send files on ftp location.
# Date Published: 18-Aug-2011 7:09:33 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/PowerShell-FTP-Client-db6fe0cb
# Tags: Powershell;FTP
# ------------------------------------------------------------------

Function Set-FTPConnection
{
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[parameter(Mandatory=$true)]
		[System.Net.NetworkCredential]$Credentials,
		[parameter(Mandatory=$true)]
		[String]$Server,
		[Switch]$EnableSsl = $False,
		[Switch]$ignoreCert = $False,
		[Switch]$KeepAlive = $False,
		[Switch]$UseBinary = $False,
		[Switch]$UsePassive = $False,
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Server,"Connect to FTP Server")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($Server)
			$Request.Credentials = $Credentials
			$Request.EnableSsl = $EnableSsl
			$Request.KeepAlive = $KeepAlive
			$Request.UseBinary = $UseBinary
			$Request.UsePassive = $UsePassive
			$Request | Add-Member -MemberType NoteProperty -Name ignoreCert -Value $ignoreCert

			$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$ignoreCert}
				$Response = $Request.GetResponse()
				$Response.Close()
				
				if((Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue) -eq $null)
				{
					New-Variable -Scope Global -Name $Session -Value $Request
				}
				else
				{
					Set-Variable -Scope Global -Name $Session -Value $Request
				}
				
				Return $Response
			}
			Catch
			{
				$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
				Write-Warning $Error
			}
		}
	}
	
	End{}				
}

Function Get-FTPChildItem
{
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
        $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		if($Path -match "ftp://")
		{
			$RequestUri = $Path
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path
		}
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get child items from ftp location.")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive
				
				$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$Response = $Request.GetResponse()

					[System.IO.StreamReader]$Stream = $Response.GetResponseStream()

					$Array = @()
					[string]$Line = $Stream.ReadLine()
					While ($Line)
					{
						$null, [string]$isDirectory, [string]$flag, [string]$link, [string]$userName, [string]$groupName, [string]$size, [string]$date, [string]$name = `
						[regex]::split($Line,'^([d-])([rwxt-]{9})\s+(\d{1,})\s+([A-Za-z0-9-]+)\s+([A-Za-z0-9-]+)\s+(\d{1,})\s+(\w+\s+\d{1,2}\s+\d{1,2}:?\d{2})\s+(.+?)\s?$',"SingleLine,IgnoreCase,IgnorePatternWhitespace")

						$LineObj = New-Object PSObject -Property @{            
        					Dir           = $isDirectory
							Right         = $flag               
        					Ln            = $link               
        					User          = $userName        
        					Group         = $groupName      
        					Size          = $size      
        					ModifiedDate  = $date    
        					Name          = $name           
        				} 
						
						if($LineObj.Dir)
						{
							$Array += $LineObj
						}
						$Line = $Stream.ReadLine()
					}
					
					$Response.Close()
					if($Array.count -eq 0)
					{
						Return 
					}
					else
					{
						Return $Array | Select-Object Dir, Right, Ln, User, Group, Size, ModifiedDate, Name | Sort-Object -Property @{Expression="Dir";Descending=$true}, @{Expression="Name";Descending=$false} 
					}	
				}
				Catch
				{
					$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
					Write-Warning $Error
				}
			}
			else
			{
				Write-Warning "First use Set-FTPConnection to config FTP connection."
			}
		}
	}
	
	End{}				
}