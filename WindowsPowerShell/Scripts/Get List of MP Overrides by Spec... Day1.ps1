#+-------------------------------------------------------------------+  
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |  
#|{>/-------------------------------------------------------------\<}|           
#|: | Author:  Aman Dhally                                        | :|           
#| :| Email:   amandhally@gmail.com
#|: | Purpose: List of Scom OverRides    
#|: |                            
#| :| 	/^(o.o)^\    Version: 1         						  |: | 
#|{>\-------------------------------------------------------------/<}|
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |
#+-------------------------------------------------------------------+

### I set $olddate to 2 Days ago date

$olddate = (Get-Date).AddDays(-2)

## Select every Management pack and Piped it to "Get-Override)

$Mp = Get-Managementpack | Get-Override 

### Now it will show only overrides which are created after $oldDate

$Mp| Where-Object { $_.TimeAdded -gt $olddate} | select ManagementGroupId,Name,TimeAdded | fl *

######## E N D of S C R I P T #############