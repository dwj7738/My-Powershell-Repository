#Define PreReqs
$timeStamp = Get-Date -UFormat "%m-%d-%Y-%H-%M"
$systemVars = Gwmi Win32_ComputerSystem -Comp "."
$userName = $systemVars.UserName
$compName = $systemVars.Name

#User Vars
$serviceName = "Spooler" # Spooler will check the Print Spooler <<< Change To Suit Your needs
$errorLog = "C:\Temp\Log_"+$serviceName + "_"+$timeStamp + "_Errors.txt" #Service Not Installed
$fullLog = "C:\Temp\Log_"+$serviceName + "_"+$timeStamp + "_All.txt" #Services Needed To Be Started / Running

#Write Some Info To Logs
"Check Service: " + $serviceName > $errorLog; Get-Date >> $errorLog; $compName >> $errorLog; $userName >> $errorLog; "_____________" >> $errorLog; "" >> $errorLog;
"Check Service: " + $serviceName > $fullLog; Get-Date >> $fullLog; $compName >> $fullLog; $userName >> $fullLog; "_____________" >> $fullLog; "" >> $fullLog;

# Define Functions
function Get-NetView {
	switch -regex (NET.EXE VIEW) { "^\\\\(?<Name>\S+)\s+" {$matches.Name}}
}

function Process-PCs ($currentName) {
	$olStatus = Ping-Address $currentName
	If ($olStatus -eq "True") {
		Check-Service $currentName
	}
	#Else {Write-Host "PC Not Online"}
	Write-Host " "
}

function Ping-Address ($pingAddress) {
	$ping = new-object system.net.networkinformation.ping
	$pingReply = $ping.send($pingAddress)
	If ($pingReply.status -eq "Success") {
		Return "True"
	}
	Else {
		Return "False"
	}
}

function Check-Service ($currentName) {
	$currentService = Get-Service -ComputerName $currentName -Name $serviceName -ErrorAction SilentlyContinue
	If ($currentService.Status -eq $Null){
		$currentServiceStatus = "Not Installed"
		$currentName >> $errorLog
	}
	ElseIf ($currentService.Status -eq "Running"){
		$currentServiceStatus = "Running"
	}
	ElseIf ($currentService.Status -eq "Stopped"){
		$currentServiceStatus = "Stopped"
	}
	Else {
		$currentServiceStatus = "Unknown"
	}

	Write-Host $serviceName " is " $currentServiceStatus " on " $currentName
	$serviceName + " was " + $currentServiceStatus + " on " + $currentName >> $fullLog
	If ($currentService.Status -eq "Stopped"){
		Write-Host "Service was stoppped, trying to start it . . ."
		$currentService | Start-Service -ErrorAction SilentlyContinue
		$recheckService = Get-Service -ComputerName $currentName -Name $serviceName -ErrorAction SilentlyContinue
		If ($recheckService.Status -eq "Running"){
			"   Service Successfully Started" >> $fullLog
		}
		Else {
			"   Service Could Not Be Started" >> $fullLog
		}
	}
}


#Run Everything
cls
Get-NetView | %{Process-PCs $_}
# Test a single PC, Uncomment line below change pc name and comment line above
# Process-PCs "localhost" | %{Process-PCs $_}