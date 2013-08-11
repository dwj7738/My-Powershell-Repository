#+-------------------------------------------------------------------+   
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |   
#|{>/-------------------------------------------------------------\<}|            
#|: | Author:  Aman Dhally                                        | :|            
#| :| Email:   amandhally@gmail.com 
#|: | Purpose: Flush IP address, renew it , Flush DNS, Register DNS      
#|: |                    Date: 24-May-2012        
#| :|Blog:http://newdelhipowershellusergroup.blogspot.in/ 
#| :| 
#| :|     /^(o.o)^\         Version: 1                                  |: |  
#|{>\-------------------------------------------------------------/<}| 
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = | 
#+-------------------------------------------------------------------+ 

# Date 24-May-2012 

# Funcationality : Flush DNS , Release IP Address | Register Ip Address | Register DNS  

# Flush the DNS Cache  
ipconfig /flushDns | Out-Null 
Write-Host "DNS Cache Flushed" -ForegroundColor Green 

# Release the Ip-AdDress 

ipconfig /release | Out-Null 
Write-Host "Ip-Adresses Flushed  now Renewing the Ip-Adress" -ForegroundColor Green 

# Sleep for 4 Seconds 

sleep 4 

# Renew the Ip-Address 

ipconfig /renew | Out-Null 
Write-Host "Ip-Adress Renewed" -ForegroundColor Green 


# Register the DNS 
ipconfig /registerdns | Out-Null 
Write-Host "DNS Regsitered" -ForegroundColor Green 


# End of Script ## Aman Dhallya 