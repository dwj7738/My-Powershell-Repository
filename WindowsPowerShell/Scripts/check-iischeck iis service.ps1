
#--name Untitled*
#--multi --hideoutput
#--origin PowerSE
#
# POWERVI OPTIONS
# name - script name for PowerVI Menu - may contain spaces but no special characters
# multi - handles multiple VMware objects - without this option PowerVI will execute the script once per object.
# hideoutput - script handles any output
# origin - credit for where it came from
# powergadgets - uses powergadgets
# full - Run PowerShell stand-along (out of process instead of inprocess).
# predefinedvariables - extra PowerShell variables that can be passed to script from PowerVI
#   Host: psvmHostCluster, psvmHostDatastores, psvmHostVSwitch, psvmHostPGroup, psvmHostNetwork  
#   VM: psvmCluster, psvmHost, psvmRespool, psvmDatastore, psvmNetwork, psvmDatacenter, psvmVSwitch, psvmPGroup 
# inputbox - Prompt the user for an input 


## Check Service
## 
## Use to check a service on a remote server and if it is not running,
## start it and send an email to warn. Added a ping request to 

####################################################################################
#PoSH script to check if a server is up and if it is check for a service.
#If the service isn't running, start it and send an email
# JK - 7/2009
####################################################################################

$erroractionpreference = "SilentlyContinue"

$i = "localhost" 	#Server Name
$service = "iisadmin" 	#Service to monitor

 $ping = new-object System.Net.NetworkInformation.Ping
    $rslt = $ping.send($i)
        if ($rslt.status.tostring() -eq "Success")
{
     write-Output $rslt
	 
		$b = get-wmiobject win32_service -computername $i -Filter "Name = '$service'"
write-Output $b.state

	If ($b.state -eq "stopped")
	{
	$b.startservice()

	#$emailFrom = "services@yourdomain.com"
	#$emailTo = "you@yourdomain.com"
	$subject = "$service Service has restarted on $i"
	$body = "The $service service on $i has crashed and been restarted"
	#$smtpServer = "xx.yourdomain.com"
	#$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	#$smtp.Send($emailFrom, $emailTo, $subject, $body)
	write-output $subject
	write-Output $body
	
	}
	
	else
	{exit}

}

else
{exit}