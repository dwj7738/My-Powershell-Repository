# Change the following variables based on your environment
$html_file_dir = "C:\PS_Scripts"
$server_file = "C:\PS_Scripts\servers.txt"
$from_address = "myemail@something.com"
$to_address = "whereiwanttosendit@something.com"
$email_gateway = "smtp.something.com" # Can either be DNS name or IP address to SMTP server
# The seventh line from the bottom (line 167) is used if your smtp gateway requires authentication. If you require smtp authentication
# you must uncomment it and set the following variables.
$smtp_user = ""
$smtp_pass = ""

# Change the following variables for the style of the report.
$background_color = "rgb(140,166,193)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$server_name_font = "Arial"
$server_name_font_size = "20px"
$server_name_bg_color = "rgb(77,108,145)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$heading_font = "Arial"
$heading_font_size = "14px"
$heading_name_bg_color = "rgb(95,130,169)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$data_font = "Arial"
$data_font_size = "11px"

# Colors for space
$very_low_space = "rgb(255,0,0)" # very low space equals anything in the MB
$low_space = "rgb(251,251,0)" # low space is less then or equal to 10 GB
$medium_space = "rgb(249,124,0)" # medium space is less then or equal to 100 GB

###########################################################################
#### NO CHANGES SHOULD BE MADE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
###########################################################################
# Define some variables
$ErrorActionPreference = "SilentlyContinue"
$date = Get-Date -UFormat "%Y%m%d"
$html_file = New-Item -ItemType File -Path "$html_file_dir\DiskSpace_$date.html" -Force
# Create the file
$html_file

# Function to be used to convert bytes to MB or GB or TB
Function ConvertBytes {
	param($size)
	If ($size -lt 1MB) {
		$drive_size = $size / 1KB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' KB'
	}elseif ($size -lt 1GB){
		$drive_size = $size / 1MB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' MB'
	}ElseIf ($size -lt 1TB){ 
		$drive_size = $size / 1GB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' GB'
	}Else{
		$drive_size = $size / 1TB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' TB'
	}
}

# Create the header and footer contents of the html page for output
$html_header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Server Drive Space</title>
<style type="text/css">
.serverName { text-align:center; font-family:"' + $server_name_font + '"; font-size:' + $server_name_font_size + `
	'; font-weight:bold; background-color: ' + $server_name_bg_color + '; border: 1px solid black; width: 150px; }
.headings { text-align:center; font-family:"' + $heading_font + '"; font-size:' + $heading_font_size + `
	'; font-weight:bold; background-color: ' + $heading_name_bg_color + '; border: 1px solid black; width: 150px; }
.data { font-family:"' + $data_font + '"; font-size:' + $data_font_size + '; border: 1px solid black; width: 150px; }
#dataTable { border: 1px solid black; border-collapse:collapse; }
body { background-color: ' + $background_color + '; }
#legend { border: 1px solid black; position:absolute; right:500px; top:10px; }
</style>
<script language="JavaScript" type="text/javascript">
<!--

function zxcWWHS(){
 if (document.all){
	zxcCur=''hand'';
	zxcWH=document.documentElement.clientHeight;
	zxcWW=document.documentElement.clientWidth;
	zxcWS=document.documentElement.scrollTop;
	if (zxcWH==0){
		zxcWS=document.body.scrollTop;
		zxcWH=document.body.clientHeight;
		zxcWW=document.body.clientWidth;
	}
}
else if (document.getElementById){
	zxcCur=''pointer'';
	zxcWH=window.innerHeight-15;
	zxcWW=window.innerWidth-15;
	zxcWS=window.pageYOffset;
}
zxcWC=Math.round(zxcWW/2);
return [zxcWW,zxcWH,zxcWS];
}


window.onscroll=function(){
	var img=document.getElementById(''legend'');
	if (!document.all){ img.style.position=''fixed''; window.onscroll=null; return; }
	if (!img.pos){ img.pos=img.offsetTop; }
	img.style.top=(zxcWWHS()[2]+img.pos)+''px'';
}
//-->
</script>
</head>
<body>'

$html_footer = '</body>
</html>'

# Start to create the reports file
Add-Content $html_file $html_header

# Retrieve the contents of the server.txt file, this file should contain either the
# ip address or the host name of the machine on a single line. Loop through the file
# and get the drive information.
Get-Content $server_file |`
ForEach-Object { 
	# Get the hostname of the machine
	$hostname = Get-WmiObject -Impersonation Impersonate -ComputerName $_ -Query "SELECT Name From Win32_ComputerSystem"
	$name = $hostname.Name.ToUpper()
	Add-Content $html_file ('<Table id="dataTable"><tr><td colspan="3" class="serverName">' + $name + '</td></tr>
		<tr><td class="headings">Drive Letter</td><td class="headings">Total Size</td><td class="headings">Free Space</td></tr>')

	# Get the drives of the server
	$drives = Get-WmiObject Win32_LogicalDisk -Filter "drivetype=3" -ComputerName $_ -Impersonation Impersonate

	# Now that I have all the drives, loop through and add to report
	ForEach ($drive in $drives) {
		$space_color = ""
		$free_space = $drive.FreeSpace
		If ($free_space -le 1073741824) {
			$space_color = $very_low_space
		}elseif ($free_space -le 10737418240) {
			$space_color = $low_space
		}elseif ($free_space -le 107374182400) {
			$space_color = $medium_space
		}

		Add-Content $html_file ('<tr><td class="data">' + $drive.deviceid + '</td><td class="data">' + (ConvertBytes $drive.size) + `
			'</td><td class="data" bgcolor="' + $space_color + '">' + (ConvertBytes $drive.FreeSpace) + '</td></tr>')
	}
	# Close the table
	Add-Content $html_file ('</table></br><div id="legend">
		<Table><tr><td style="font-size:12px">Less then or equal to 1 GB</td><td bgcolor="' + $very_low_space + '" width="10px"></td></tr>
		<tr><td style="font-size:12px">Less then or equal to 10 GB</td><td bgcolor="' + $low_space + '" width="10px"></td></tr>
		<tr><td style="font-size:12px">Less then or equal to 100 GB</td><td bgcolor="' + $medium_space + '" width="10px"></td></tr>
		</table></div>')
}

# End the reports file
Add-Content $html_file $html_footer

# Email the file
$mail = New-Object System.Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($html_file)
$mail.From = $from_address
$mail.To.Add($to_address)
$mail.Subject = "Server Diskspace $date"
$mail.Body = "The diskspace report file is attached."
$mail.Attachments.Add($att)
$smtp = New-Object System.Net.Mail.SmtpClient($email_gateway)
#$smtp.Credentials = New-Object System.Net.NetworkCredential($smtp_user,$smtp_pass)

$smtp.Send($mail)
$att.Dispose()

# Delete the file
Remove-Item $html_file