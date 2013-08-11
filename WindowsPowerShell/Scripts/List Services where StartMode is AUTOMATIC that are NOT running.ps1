# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: List Services where StartMode is AUTOMATIC that are NOT running
# Author: Francois-Xavier Cat
# Description: This script will list services from a local or remote computer where the StartMode property is set to  Automatic  and where the state is different from RUNNING (so mostly where the state is NOT RUNNING)
# Date Published: 29-Jun-2011 11:35:24 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/dba0a313-5a74-464a-a98a-fac57ed28105
# Tags: Service List;Services
# ------------------------------------------------------------------

Get-WmiObject Win32_Service -ComputerName . |`
	where 	{($_.startmode -like "*auto*") -and `
			($_.state -notlike "*running*")}|`
			select DisplayName,Name,StartMode,State|ft -AutoSize