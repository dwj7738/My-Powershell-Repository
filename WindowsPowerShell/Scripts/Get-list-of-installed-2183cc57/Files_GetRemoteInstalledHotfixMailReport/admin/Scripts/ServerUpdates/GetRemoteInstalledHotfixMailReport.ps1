##############################################################################################
# - GetRemoteInstalledHotfixMailReport.ps1
# - Script by Tim Buntrock
# - Run this script on a server that can access the specified servers.
# - Create the folder strcuture "C:\admin\Scripts\ServerUpdates\updatefiles"
# - Add your servers to the servers textfile "C:\admin\Scripts\ServerUpdates\Servers.txt"
# - Change the "#Set E-mail variables" section -> line 23-27
##############################################################################################


#Set date variable
$date = get-date -UFormat "%d%m%Y"

#Create folder structure
#New-Item -ItemType directory -Path C:\admin\Scripts\ServerUpdates\updatefiles

#Query server and save it to a csv file
get-content "C:\admin\Scripts\ServerUpdates\Servers.txt" | Where {$_ -AND (Test-Connection $_ -Quiet)} | foreach { Get-Hotfix -computername $_ | Select CSName,Description,HotFixID,InstalledBy,InstalledOn | convertto-csv | out-file "C:\admin\Scripts\ServerUpdates\updatefiles\$_-$date.csv" } 



#Set E-mail variables !!! Enter your settings!!!
$EmailFrom = "server@my.domain.com"
$EmailTo = "Admins@my.domain.com"
$Subject = "Server Update Report $date"
$Body = "Find attached the Update reports."
$SMTPServer = "smtpserver1.my.domain.com"
 

#Files location
$UpdateDir = “C:\admin\Scripts\ServerUpdates\updatefiles”

 
#Send Email with reports
Get-ChildItem $UpdateDir | Where {-NOT $_.PSIsContainer} | foreach {$_.fullname} | Send-MailMessage -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Priority High -To $EmailTo -From $EmailFrom

#Remove csv files located in updatefiles
remove-item -path C:\admin\Scripts\ServerUpdates\updatefiles\*.*