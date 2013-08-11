# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Shutdown-Comput<wbr />er
# Author: Fredrik Wall
# Description: Will Shutdown the local computer or a remote computer
# Date Published: 29-Dec-2009 3:26:22 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/6437edda-da63-4b8e-b1c5-d7ba5fc4bcc3
# ------------------------------------------------------------------

function Shutdown-Computer {
<#
	.Synopsis
		Will shutdown, Log Off or Reboot a remote or a local computer
	.Description
		Will shutdown, Log Off or Reboot a remote or a local computer.
		Force will shutdown open programs etc.
	.Example
		Shutdown-Computer mycomputer 'Log Off'
	Will Log Off the computer mycomputer
	.Example
		Shutdown-Computer mycomputer 'Shutdown'
	Will Shutdown the computer mycomputer
	.Example
		Shutdown-Computer mycomputer 'Reboot'
	Will Reboot the computer mycomputer
	.Example
		Shutdown-Computer mycomputer 'Power Off'
	Will Power Off the computer mycomputer	
	.Example
		Shutdown-Computer mycomputer 'Log Off' other
	Will Log Off the computer mycomputer with other credentials
	.Notes
	 NAME:      Shutdown-Computer
	 AUTHOR:    Fredrik Wall, fredrik@poweradmin.se
	 BLOG:		poweradmin.se/blog
	 LASTEDIT:  12/29/2009
#>

param ($computer, $type, $cred)
	switch ($type) {
	'Log Off' {$ShutdownType = "0"}
	'Shutdown' {$ShutdownType = "1"}
	'Reboot' {$ShutdownType = "2"}
	'Forced Log Off' {$ShutdownType = "4"}
	'Forced Shutdown' {$ShutdownType = "5"}
	'Forced Reboot' {$ShutdownType = "6"}
	'Power Off' {$ShutdownType = "8"}
	'Forced Power Off' {$ShutdownType = "12"}
	}
	
	$Error.Clear()
	if ($cred -eq $null) {
		trap { continue }
		(Get-WmiObject win32_operatingsystem -ComputerName $computer -ErrorAction SilentlyContinue).Win32Shutdown($ShutdownType)
	}
	
	if ($cred -eq "other") {
		trap { continue }
		(Get-WmiObject win32_operatingsystem -ComputerName $computer -ErrorAction SilentlyContinue -Credential (get-Credential)).Win32Shutdown($ShutdownType)
	}
}