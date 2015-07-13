############################################################################
#                                                                          #
#  *** THIS SCRIPT IS PROVIDED WITHOUT WARRANTY, USE AT YOUR OWN RISK ***  #
#                                                                          #
# Author: David Hall, signalwarrant.com                                    #
#                                                                          #
# This script will allow you to stop the wuauserv service on a client,     #
# check to see if the softwaredistribution exists and if so delete it.     #
# Once the service is stopped and the folder is deleted it restarts the    #
# wuauserv service and forces WSUS checkin.                                #                 
#                                                                          #
# This is my solution to Windows Update error 8024402C on Windows Server   #
# 2008 Servers.                                                            #
#                                                                          #
############################################################################
$path = "c:\windows\SoftwareDistribution"


# Stopping the wuauserv service
Write-host -foregroundcolor Cyan "1. STOPPING wuauserv service..."
Stop-Service wuauserv  

# This is just to make sure the wuauserv service has time to stop before moving 
# on to the next portion of the script.
[System.Threading.Thread]::Sleep(2500)

# Testing to see if the c:\windows\SoftwareDistribution folder exists
if (Test-Path $path) {
    
    # If the folder exists Delete it and restart the wuauserv service,
    # force WSUS checkin and exit
    Write-host -foregroundcolor Red "2. SoftwareDistribution Folder Exists... Deleting"
    [System.Threading.Thread]::Sleep(1500)
    Remove-Item -path $path -recurse
    Write-host -foregroundcolor Red "3. *** DELETED ***"
    [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "4. STARTING wuauserv service..."
    Start-Service wuauserv 
    [System.Threading.Thread]::Sleep(2500)
    Write-host -foregroundcolor Cyan "5. Forcing WSUS Checkin"
    [System.Threading.Thread]::Sleep(1500)
    Invoke-Command {wuauclt.exe /detectnow}
    Write-host -foregroundcolor Cyan "6. Checkin Complete"
    Exit
    
    } else {
    
    # If the folder does not exist restart the wuauserv service,
    # force WSUS checkin and exit
    Write-host -foregroundcolor Red "2. SoftwareDistribution Folder does not exists, STARTING wuauserv"
    [System.Threading.Thread]::Sleep(1500)
    Write-host -foregroundcolor Cyan "3. STARTING wuauserv service..."
    Start-Service wuauserv
    [System.Threading.Thread]::Sleep(2500)
    Write-host -foregroundcolor Cyan "4. Forcing WSUS Checkin"
    [System.Threading.Thread]::Sleep(1500)
    Invoke-Command {wuauclt.exe /detectnow}
    Write-host -foregroundcolor Cyan "5. Checkin Complete"
    Exit
    }




 