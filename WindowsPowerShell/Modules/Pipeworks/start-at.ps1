function Start-At
{
    <#
    .Synopsis
        Starts scripts at a time or event
    .Description
        Starts scripts at a time, an event, or a change in a table
    .Example
        Start-At -Boot -RepeatEvery "0:30:0" -Name LogTime -ScriptBlock {         
            "$(Get-Date)" | Set-Content "$($env:Public)\$(Get-Random).txt"

        }
    #>
    [CmdletBinding(DefaultParameterSetName='StartAtTime')]
    param(
    # The scriptblock that will be run
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ScriptBlock[]]$ScriptBlock,    
    
    # The time the script will start
    [Parameter(Mandatory=$true, ParameterSetName='StartAtTime')]
    [DateTime]$Time,

    # The event ID of interest
    [Parameter(Mandatory=$true, ParameterSetName='StartAtSystemEvent')]
    [Uint32]$EventId,

    # The event log where the eventID is found
    [Parameter(Mandatory=$true, ParameterSetName='StartAtSystemEvent')]
    [string]$EventLog,

    # The table name that contains data to process
    [Parameter(Mandatory=$true, ParameterSetName='StartAtTableData')]
    [Parameter(Mandatory=$true, ParameterSetName='StartAtSqlData')]
    [string]$TableName,

    # The name of the user table.  If an OwnerID is found on an object, and user is found in the a usertable, then the task will be run as that user 
    [Parameter(ParameterSetName='StartAtTableData')]
    [Parameter(ParameterSetName='StartAtSqlData')]
    [string]$UserTableName,

    # The filter used to scope queries for table data
    [Parameter(Mandatory=$true, ParameterSetName='StartAtTableData')]
    [string]$Filter,
    
    # The filter used to scope queries for table data
    [Parameter(Mandatory=$true, ParameterSetName='StartAtSQLData')]
    [string]$Where,

    # The name of the  setting containing the storage account
    [Parameter(ParameterSetName='StartAtTableData')]    
    [Parameter(ParameterSetName='StartAtSqlData')]
    [Parameter(ParameterSetName='StartAtNewEmail')]
    [string]$StorageAccountSetting = "AzureStorageAccountName",

    # The name of the setting containing the storage key
    [Parameter(ParameterSetName='StartAtTableData')]    
    [Parameter(ParameterSetName='StartAtSqlData')]
    [Parameter(ParameterSetName='StartAtNewEmail')]
    [string]$StorageKeySetting = "AzureStorageAccountKey",

    # Clears a property on the object when the item has been handled
    [Parameter(ParameterSetName='StartAtTableData')]    
    [string]$ClearProperty,

    # The name of the setting containing the email username
    [Parameter(ParameterSetName='StartAtNewEmail',Mandatory=$true)]
    [string]$EmailUserNameSetting,

    # The name of the setting containing the email password
    [Parameter(ParameterSetName='StartAtNewEmail',Mandatory=$true)]
    [string]$EmailPasswordSetting,

    # The display name of the inbox receiving the mail.
    [Parameter(ParameterSetName='StartAtNewEmail',Mandatory=$true)]
    [string]$SentTo,

    # The name of the setting containing the storage key
    [Parameter(ParameterSetName='StartAtSQLData')]    
    [string]$ConnectionStringSetting = "SqlAzureConnectionString",

    # The partition containing user information.  If the items in the table have an owner, then the will be run in an isolated account.
    [Parameter(ParameterSetName='StartAtTableData')]    
    [string]$UserPartition = "Users",

    # The timespan in between queries
    [Parameter(ParameterSetName='StartAtTableData')]
    [Parameter(ParameterSetName='StartAtSQLData')]
    [Parameter(ParameterSetName='StartAtNewEmail')]
    [Timespan]$CheckEvery = "0:15:0",
    
    # The randomized delay surrounding a task start time.  This can be used to load-balance expensive executions
    [Parameter(ParameterSetName='StartAtTime')]
    [Timespan]$Jitter,

    # If set, the task will be started every day at this time
    [Parameter(ParameterSetName='StartAtTime')]
    [Switch]$EveryDay,
    
    # The interval (in days) in between running the task
    [Parameter(ParameterSetName='StartAtTime')]
    [Switch]$DayInterval,        


    # If set, the task will be started whenever the machine is locked
    [Parameter(ParameterSetName='StartAtLock')]
    [Switch]$Lock,


    # If set, the task will be started whenever the machine is unlocked
    [Parameter(Mandatory=$true,ParameterSetName='StartAtBoot')]
    [Switch]$Boot,

    # If set, the task will be started whenever the machine is unlocked
    [Parameter(Mandatory=$true,ParameterSetName='StartAtAnyLogon')]
    [Switch]$Logon,
    
    # If set, the task will be started whenever the machine is unlocked
    [Parameter(Mandatory=$true,ParameterSetName='StartAtUnlock')]
    [Switch]$Unlock,

    # If set, the task will be started whenever a user logs onto the local machine
    [Parameter(Mandatory=$true,ParameterSetName='StartAtLocalLogon')]
    [Switch]$LocalLogon,

    # If set, the task will be started whenever a user logs off of a local machine
    [Parameter(Mandatory=$true,ParameterSetName='StartAtLocalLogoff')]
    [Switch]$LocalLogoff,

    # If set, the task will be started whenever a user disconnects via remote deskop
    [Parameter(Mandatory=$true,ParameterSetName='StartAtRemoteLogon')]
    [Switch]$RemoteLogon,

    # If set, the task will be started whenever a user disconnects from remote desktop
    [Parameter(Mandatory=$true,ParameterSetName='StartAtRemoteLogoff')]
    [Switch]$RemoteLogoff,

    # Starts the task as soon as possible
    [Parameter(Mandatory=$true,ParameterSetName='StartASAP')]
    [Alias('ASAP')]
    [Switch]$Now,

    # IF provided, will scope logons or connections to a specific user
    [Parameter(ParameterSetName='StartAtLock')]
    [Parameter(ParameterSetName='StartAtUnLock')]
    [Parameter(ParameterSetName='StartAtAnyLogon')]
    [Parameter(ParameterSetName='StartAtAnyLogoff')]
    [Parameter(ParameterSetName='StartAtLocalLogon')]
    [Parameter(ParameterSetName='StartAtLocalLogoff')]
    [Parameter(ParameterSetName='StartAtRemoteLogon')]
    [Parameter(ParameterSetName='StartAtRemoteLogoff')]
    [string]$ByUser,

    # The user running the script
    [Management.Automation.PSCredential]
    $As,


    # The name of the computer the task will be run on.  If not provided, the task will be run locally
    [Alias('On')]
    [string]
    $ComputerName,

    # If set, the task will repeat at this frequency.
    [Timespan]$RepeatEvery,

    # If set, the task will repeat for up to this timespan.  If not set, the task will repeat indefinately.
    [Timespan]$RepeatFor,

    # A name for the task.
    [string]
    $Name,

    # The name of the folder within Task Scheduler.    
    [string]
    $Folder,

    # If set, will not exist the started task.
    [Switch]
    $NoExit

    )

    process {
        #region Connect to the scheduler
        $sched = New-Object -ComObject Schedule.Service
        $sched.Connect()
        $task = $sched.NewTask(0)
        #endregion Connect to the scheduler


        $description = ""
        #region Add the actions to the task
        foreach ($sb in $ScriptBlock) {

            $action = $task.Actions.Create(0)
            $action.Path = Join-Path $psHome "PowerShell.exe" 
        
        
            $action.Arguments = " -WindowStyle Minimized -Sta"
        
        
            if ($NoExit) {
                $Action.Arguments += " -NoExit"
            }
            $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($sb))
            $action.Arguments+= " -encodedCommand $encodedCommand"

        }
        #endregion Add the actions to the task

        if ($PSCmdlet.ParameterSetName -eq 'StartAtTime') {
        
                $days = (Get-Culture).DateTimeFormat.DayNames
                $months  = (Get-Culture).DateTimeFormat.MonthNames
                if ($PSBoundParameters.EveryDay -or $PSBoundParameters.DayInterval) {
                    $dailyTrigger = $task.Triggers.Create(2)

                    if ($psBoundParameters.DayInterval) {
                        $dailyTrigger.DaysInterval = $psBoundParameters.DayInterval
                    }
                } else {
                    # One time
                    $timeTrigger = $task.Triggers.Create(1)

                    
                }


        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtLogon') {
            $logonTrigger= $task.Triggers.Create(9)
            $description += " At Logon "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtSystemEvent') {
            $evtTrigger= $task.Triggers.Create(0)
            $evtTrigger.Subscription = "
<QueryList>
    <Query Id='0' Path='$($EventLog)'>
        <Select Path='$($EventLog)'>
            *[System[EventID=$($EventId)]]
        </Select>
    </Query>
</QueryList>                
"                
            
            $description += " At Event $EventId"
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtLocalLogon') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 1 
            $description += " At Local Logon "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtLocalLogoff') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 2 
            $description += " At Local Logoff "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtRemoteLogoff') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 3 
            $description += " At Remote Logon "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtRemoteLogoff') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 4 
            $description += " At Remote Logoff "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtLock') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 7 
            $description += " At Lock"
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtUnlock') {
            $stateTrigger= $task.Triggers.Create(11)
            $stateTrigger.StateChange = 8 
            $description += " At Unlock "
                
            
        } elseif ($psCmdlet.ParameterSetName -eq 'StartASAP') {
            $regTrigger = $task.Triggers.Create(7)
            $description += " ASAP "
        } elseif ($psCmdlet.ParameterSetName -eq 'StartAtBoot') {
            $bootTrigger = $task.Triggers.Create(8)
            
            $description += " OnBoot "
        } elseif ('StartAtTableData', 'StartAtSqlData', 'StartAtNewEmail' -contains $PSCmdlet.ParameterSetName) {            
            if (-not $PSBoundParameters.As) {
                Write-Error "Must supply credential for table based tasks"
                return 
            }
            # Schedule it as the user that will check

            $description += " New SQL Data from $TableName "
            IF ($PSCmdlet.ParameterSetName -eq 'StartAtNewEmail') {
                $check= "
Get-Email -UserNameSetting '$EmailUserNameSetting' -PasswordSetting '$EmailPasswordSetting' -Unread -Download -To '$SentTo'"
            } elseif ($psCmdlet.ParameterSetName -eq 'StartAtSqlData') {
                $check= "
Select-Sql -ConnectionStringOrSetting '$ConnectionStringSetting' -FromTable '$tableName' -Where '$Where'"
            } elseif ($psCmdlet.ParameterSetName -eq 'StartAtTableData') {
                $check = "
Search-AzureTable -TableName '$TableName' -Filter `"$Filter`" -StorageAccount `$storageAccount -StorageKey `$storageKey"
                
                if ((-not $UserTableName) -and $TableName) {
                    $UserTableName = $TableName
                }

            } 
            
                


            $saveMyCred = "
Add-SecureSetting -Name '$StorageAccountSetting' -String '$(Get-SecureSetting $StorageAccountSetting -ValueOnly)'
Add-SecureSetting -Name '$StorageKeySetting' -String '$(Get-SecureSetting $StorageKeySetting -ValueOnly)'
                "

            $saveMyCred = [ScriptBlock]::Create($saveMyCred)
            # Start-At -ScriptBlock $saveMyCred -As $As -Now
            
            

            

            $checkTable = "
Import-Module Pipeworks -Force
`$storageAccount = Get-SecureSetting '$StorageAccountSetting' -ValueOnly
`$storageKey = Get-SecureSetting '$StorageKeySetting' -ValueOnly

$check |
    Sort-Object { 
        (`$_.Timestamp -as [Datetime])
    } -Descending |
    Foreach-Object { 
        `$item = `$_
        `$userTableName = '$UserTableName'
        if (-not `$userTableName) {
            `$scriptOutput = . {
                $ScriptBlock
            }
            `$updatedItem  =`$item | 
                Add-Member NoteProperty ScriptResults `$scriptOutput -Force -PassThru 

        } else {        
            if (`$item.From.Address) {                
                `$userFound = Search-AzureTable -TableName '$UserTableName' -Filter `"PartitionKey eq '$UserPartition' and UserEmail eq '`$(`$item.From.Address)'`" -StorageAccount `$storageAccount -StorageKey `$storageKey
            } elseif (`$item.OwnerID) {
                # Run it as the owner
                `$userFound = Search-AzureTable -TableName '$UserTableName' -Filter `"PartitionKey eq '$UserPartition' and RowKey eq '`$(`$item.OwnerID)'`" -StorageAccount `$storageAccount -StorageKey `$storageKey
            }
            if (-not `$userFound) { 
                Write-Error 'User Not Found'
                return 
            }
            
            if (-not `$item.OwnerID) {
                return
            } 


            `$id = `$item.OwnerID[0..7+-1..-12] -join ''
            `$userExistsOnSystem = net user `"`$id`" 2>&1
            
            if (`$userExistsOnSystem[0] -as [Management.Automation.ErrorRecord]) {
                # They don't exist, make them 
                # `$completed = net user `"`$id`" `"`$(`$userFound.PrimaryAPIKey)`" /add /y
                `$objOu = [ADSI]`"WinNT://`$env:ComputerName`"
                `$objUser = `$objOU.Create(`"User`", `$id)
                `$objUser.setpassword(`$userFound.PrimaryAPIKey)
                `$objUser.SetInfo()
                `$objUser.description = `$userFound.UserID
                `$objUser.SetInfo()
            }

            `$targetPath = Split-path `$home 
            `$targetPath = Join-Path `$targetPath `$id               

            `$innerScript = {
                `$in = `$args 
                    
                foreach (`$item in `$in) {                         
                    if (`$item -is [Array]) {
                        `$item = `$item[0]
                    }
                    . {
                        $ScriptBlock       
                    } 2>&1
                    
                    `$null = `$item
                }                                                                  
            }

            `$asCred = New-Object Management.Automation.PSCredential `"`$id`", (ConvertTo-SecureString -Force -AsPlainText `"`$(`$userFound.PrimaryAPIKey)`")
            `$scriptOutput = Start-Job -ScriptBlock `$innerScript -Credential `$asCred -ArgumentList `$item |
                Wait-Job |
                Receive-Job

            `$compressedResults = (`$scriptOutput | Write-PowerShellHashtable) | Compress-Data -String {  `$_ } 

            `$updatedItem  =`$item | 
                Add-Member NoteProperty ScriptResults (`$compressedResults)  -Force -PassThru 


            if (`$item.RowKey -and `$item.PartitionKey) {
                `$clearProperty = '$ClearProperty'
                if (`$clearProperty) {
                    `$null = `$updatedItem.psobject.properties.Remove(`$clearProperty)
                }
                `$updatedItem |
                    Update-AzureTable -TableName '$TableName' -Value { `$_ } 
            }
            
        }   
        
        
         
    }
"

            $checkTable = [ScriptBlock]::Create($checkTable)

            Start-At -Boot -As $as -ScriptBlock $checkTable -RepeatEvery $CheckEvery -NoExit:$NoExit -Name:"${Name}_AtBoot" -Folder:$Folder
            Start-At -Now -As $as -ScriptBlock $checkTable -RepeatEvery $CheckEvery -NoExit:$NoExit -Name:"${Name}_Now" -Folder:$Folder
        }


        
        

        if ($task.Triggers.Count) {
            $task.Settings.MultipleInstances = 3
            foreach ($trig in $task.Triggers) {
                if ($PSBoundParameters.Time) {
                    $trig.StartBoundary = $Time.ToString("s")
                } else {
                    $trig.StartBoundary = [DateTime]::Now.ToString("s")
                }
                if ($PSBoundParameters.RepeatEvery)  {
                    $trig.Repetition.Interval = "PT$($RepeatEvery.TotalMinutes -as [uint32])M"
                }
                if ($PSBoundParameters.RepeatFor) {
                    $trig.Repetition.Duration = "PT$($RepeatFor.TotalMinutes -as [uint32])M"
                }
                if ($PSBoundParameters.Jitter) {
                    $trig.RandomDelay = "PT$($Jitter.TotalMinutes -as [uint32])M"
                }
                if ($psBoundParameters.ByUser) {
                    $trig.UserID = $PSBoundParameters.ByUser
                    $description += " ByUser $($psBoundParameters.ByUser.Replace('\','_'))"
                }

            }

            $taskNAme = if ($Name) {
                $Name
            } else {
                if ($as) {
                    "Start-At $Description as $($As.GetNetworkCredential().UserName) "
                } else {
                    "Start-At $Description"
                }
            }


            $taskPath = 
                if ($Folder) {
                    Join-Path $folder $taskNAme 
                } else {
                    $taskNAme 
                }


            if ($as) {
                $task.Principal.RunLevel = 1                
                 
                $registeredTask = $sched.GetFolder("").RegisterTask($taskPath, $task.XmlText, 6, $As.UserName, $As.GetNetworkCredential().Password, 6, $null)
            } else {
                $registeredTask = $sched.GetFolder("").RegisterTask($taskPath, $task.XmlText, 6, "", "", 3, $null)
            }
        }
        




        
    }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCUf6e8t1dCecodZ9oGqT21t+
# z7ygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIjN725cDYx75aJ7
# rJe92YLYl98uMA0GCSqGSIb3DQEBAQUABIIBAG6MLPZOPbCHO8mdCLpt9Ekxo/Il
# 98UL91KRSVFjcdXKKpoKt0X0bGrNC/BRr3dO/hjKhMKsho7Ql/XRsJDmeyUcvcHg
# AGiZhxGHMMB2StWXlOq8n/6ZJAcre/T91FVzrPE6h7pVqbHpFFVcbCofT8E5OA0t
# qzZf4gxTg4/xAt+vlt9DoXmtDMoWEMViR1ggBOzCfUx8JizIXepifSdJnivabtEF
# TI0jPKCG8gMw9GE8eT4lgDqvUKmJjqOjrGMwlzyhpcdA6wKIgU2NVGeTZsnS/Ryf
# V6jXD4QbK590EqNG3L8TZngMgRy/pIucK6UFUOd5Ql5OxTs36FOWhlXqgUE=
# SIG # End signature block
