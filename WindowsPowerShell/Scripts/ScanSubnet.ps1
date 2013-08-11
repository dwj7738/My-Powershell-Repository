#======================================================
#
#             	 Ping Hosts in IP range 
#				 and Mail Status Changes 
#						Part 1
#
#            	==> Rustam KARIMOV <==
#               	Date: 20/06/2012
#
#
#======================================================

clear
function ScanSubnet {
#Ensure Validity of entered data. Must be in "xxx.xxx.xxx." format
do {
    try {
        $numOk = $true
        $subnet = Read-Host "First 3 bits of IP subnet to scan (put dot (.) at the end"
		$ok= ($subnet -match "(\d{1,3}).(\d{1,3}).(\d{1,3})." -and -not ([int[]]$matches[1..3] -gt 255))
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($ok -eq $true) -and $numOK)

#Check if number entered is between 1-255 
do {
    try {
        $numOk = $true
        [int]$a = Read-host "Scan from (1-255)"
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($a -ge 1 -and $a -lt 256) -and $numOK)

#Check if number entered is between 1-255 
do {
    try {
        $numOk = $true
        [int]$b = Read-host "Scan To (1-255)"
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($b -ge 1 -and $b -lt 256) -and $numOK)

If (($subnet -eq "")) { 
	Write-Host No qualified data entered
	Exit 
	}

#Array of last bits of IP addresses
[array]$nrange=$a..$b

#Array of last bits of IP addresses to store time stamps later
[array]$trange=$a..$b

$cnt=0



		clear
		Write-Host ==========================Scanning hosts $subnet$a-$b==================================
		Write-Host  HostName`tActive`tTime`t`t`tResp. Time`tHost Name
		Write-Host =========================================================================================

			
		while ($t=1) #t=1 never changes, just to make it running in constant loop
		{     
		$i=0
		$cnt+=1

		foreach ($r in $nrange)
	    	{     	
			#Initial test if host is active returns Boolean
	    	$var=(Test-Connection $subnet$r -Count 1 -quiet )	
			$ip = $subnet+$r
			$fqdn=""
			
			 try {
        			$Ok = $true
					$fqdn = [net.dns]::gethostbyaddress($ip).hostname 
				}
				catch {$Ok = $false}

	        If ($var.ToString() -eq "False")
		        {	
					#Check if variable is Active then set current time and send email, if time is set in variable will skip
					#this requires to keep the time since when host was not active
					if (($trange[$r-$a] -eq "Active") -or ($trange[$r-$a] -is [int])) {
						$trange[$r-$a]=((get-date).ToString())
						
						if($cnt -ne 1) {
						#Send email with detailes of not active host
						$subject =$ip + " - " + $fqdn + " is down at " + ((get-date).ToString()) 
						foreach($mail in (gc "Mailto.txt"))
							{
							Send-MailMessage -To $mail -From "PowerShell <powershell@powershell.com>" `
							-Subject $subject `
							-SmtpServer 10.10.10.10 -Body "Notification" -BodyAsHtml
							}
						}
					}

					#print out result on corresponding line
					#i+x. X is a number of row from which to start output of current ping results
					[console]::SetCursorPosition([Console]::CursorLeft,$i+3) 
					Write-Host  $subnet$r`t`t>>>>No responce from Host since $trange[$r-$a]`t`t`t -ForegroundColor "Black"  -BackgroundColor "Red"           
	        	}
	        	else
	        	{
					#I used WMI object, parent of Test-Connection to get more info on ping status
					#$var1= Get-WmiObject win32_pingstatus -f "Address='$subnet$r' and ResolveAddressNames=$True"
					$var1= Get-WmiObject win32_pingstatus -f "Address='$subnet$r'"
					
					#Set "Active" if host was not active/pingable and send email.
					if ( ($trange[$r-$a] -ne "Active")) {
						$trange[$r-$a]="Active"
						
						if($cnt -ne 1) {
						#Generates HTML Code with Ping results in $body variable.
						$body = ($var1 | Select-Object 	@{Name="Source &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.__SERVER}}, `
										@{Name="Destination IP &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.Address}}, `
										@{Name="Bytes &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.Replysize}}, `
										@{Name="Time(ms)&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.ResponseTime}} | ConvertTo-Html)
						
						$subject =$ip + " - " + $fqdn + " is back online at " + ((get-date).ToString()) 
						#Send email with detailes of host
							foreach($mail in (gc "Mailto.txt"))
								{
								Send-MailMessage -To $mail -From "PowerShell <powershell@powershell.com>" `
								-Subject $subject `
								-SmtpServer 10.10.10.10 -Body $body.GetEnumerator() -BodyAsHtml
								}
							}
						}
					
					#print out result on corresponding line
					#i+x. X is a number of row from which to start output of current ping results
					[console]::SetCursorPosition([Console]::CursorLeft,$i+3)
					Write-Host  $subnet$r`t$var`t((get-date).ToString())`t($var1.ResponseTime.ToString())`t`t$fqdn`t`t -ForegroundColor "green"
				} 
				$i+=1
	      	}
			sleep 3				
			Write-Host `n===========================Round "#" $cnt finished at (get-date).ToString()=======================
		
		}
	}



ScanSubnet


