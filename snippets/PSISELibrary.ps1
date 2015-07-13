Function Replace-TabsWithSpace
{
    <#
        .SYNOPSIS
            Replaces a tab character with 4 spaces
        .DESCRIPTION
            This function examines the selected text in the PSIE SelectedText property and every tab
            character that is found is replaced with 4 spaces.
        .PARAMETER SelectedText
            The current contents of the SelectedText property
        .PARAMETER InstallMenu
            Specifies if you want to install this as a PSIE add-on menu
        .EXAMPLE
            Replace-TabsWithSpace -InstallMenu $true
            
            Description
            -----------
            Installs the function as a menu item.
        .NOTES
            This was written specifically for me, I had some code originally created in Notepad++ that
            used actual tabs, later I changed that to spaces, but on occasion I come accross something
            that doesn't tab shift like it should. Since I've been doing some PowerShell ISE stuff lately
            I decided to write a little function that works as an Add-On menu.
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#Replace-TabsWithSpace
    #>
    [CmdletBinding()]
    Param
        (
        $SelectedText = $psISE.CurrentFile.Editor.SelectedText,
        $InstallMenu
        )
    Begin
    {
        if ($InstallMenu)
        {
            Write-Verbose "Try to install the menu item, and error out if there's an issue."
            try
            {
                $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Replace Tabs with Space",{Replace-TabsWithSpace},"Ctrl+Alt+R") | Out-Null
                }
            catch
            {
                Return $Error[0].Exception
                }
            }
        }
    Process
    {
        Write-Verbose "Try and find the tab character in the selected PSISE text, return an error if there's an issue."
        try
        {
            $psISE.CurrentFile.Editor.InsertText($SelectedText.Replace("`t","    "))
            }
        catch
        {
            Return $Error[0].Exception
            }
        }
    End
    {
        }
    }
Function New-CommentBlock
{
    <#
        .SYNOPSIS
            Inserts a full comment block
        .DESCRIPTION
            This function inserts a full comment block that is formatted the
            way I format all my comment blocks.
        .PARAMETER InstallMenu
            Specifies if you want to install this as a PSIE add-on menu
        .EXAMPLE
            New-CommentBlock -InstallMenu $true
            
            Description
            -----------
            Installs the function as a menu item.
        .NOTES
            FunctionName : New-CommentBlock
            Created by   : Jeff Patton
            Date Coded   : 09/13/2011 12:28:10
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#New-CommentBlock
    #>
    [CmdletBinding()]
    Param
        (
        $InstallMenu
        )
    Begin
    {
        $WikiPage = ($psISE.CurrentFile.DisplayName).Substring(0,($psISE.CurrentFile.DisplayName).IndexOf("."))
        $CommentBlock = @(
            "    <#`r`n"
            "       .SYNOPSIS`r`n"
            "       .DESCRIPTION`r`n"
            "       .PARAMETER`r`n"
            "       .EXAMPLE`r`n"
            "       .NOTES`r`n"
            "           FunctionName : `r`n"
            "           Created by   : $($env:username)`r`n"
            "           Date Coded   : $(Get-Date)`r`n"
            "       .LINK`r`n"
            "           https://code.google.com/p/mod-posh/wiki/$($WikiPage)`r`n"
            "    #>`r`n")
        if ($InstallMenu)
        {
            Write-Verbose "Try to install the menu item, and error out if there's an issue."
            try
            {
                $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Insert comment block",{New-CommentBlock},"Ctrl+Alt+C") | Out-Null
                }
            catch
            {
                Return $Error[0].Exception
                }
            }
        }
    Process
    {
        if (!$InstallMenu)
        {
            Write-Verbose "Don't insert a comment if we're installing the menu"
            try
            {
                Write-Verbose "Create a new comment block, return an error if there's an issue."
                $psISE.CurrentFile.Editor.InsertText($CommentBlock)
                }
            catch
            {
                Return $Error[0].Exception
                }
            }
        }
    End
    {
        }
    }
Function New-Script
{
    <#
        .SYNOPSIS
            Create a new blank script
        .DESCRIPTION
            This function creates a new blank script based on my original template.ps1
        .PARAMETER InstallMenu
            Specifies if you want to install this as a PSIE add-on menu
        .PARAMETER ScriptName
            This is the name of the new script.
        .EXAMPLE
            New-Script -ScriptName "New-ImprovedScript"
            
            Description
            -----------
            This example shows calling the function with the ScriptName parameter
        .EXAMPLE
            New-Script -InstallMenu $true
            
            Description
            -----------
            Installs the function as a menu item.
        .NOTES
            FunctionName : New-Script
            Created by   : Jeff Patton
            Date Coded   : 09/13/2011 13:37:24
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#New-Script
    #>
    [CmdletBinding()]
    Param
        (
        $InstallMenu,
        $ScriptName
        )
    Begin
    {
        $TemplateScript = @(
        "<#`r`n"
        "   .SYNOPSIS`r`n"
        "       Template script`r`n"
        "   .DESCRIPTION`r`n"
        "       This script sets up the basic framework that I use for all my scripts.`r`n"
        "   .PARAMETER`r`n"
        "   .EXAMPLE`r`n"
        "   .NOTES`r`n"
        "       ScriptName : $($ScriptName)`r`n"
        "       Created By : $($env:Username)`r`n"
        "       Date Coded : $(Get-Date)`r`n"
        "       ScriptName is used to register events for this script`r`n"
        "       LogName is used to determine which classic log to write to`r`n"
        "`r`n"        
        "       ErrorCodes`r`n"
        "           100 = Success`r`n"
        "           101 = Error`r`n"
        "           102 = Warning`r`n"
        "           104 = Information`r`n"
        "   .LINK`r`n"
        "       https://code.google.com/p/mod-posh/wiki/Production/$($ScriptName)`r`n"
        "#>`r`n"
        "[CmdletBinding()]`r`n"
        "Param`r`n"
        "   (`r`n"
        "`r`n"    
        "   )`r`n"
        "Begin`r`n"
        "   {`r`n"
        "       `$ScriptName = `$MyInvocation.MyCommand.ToString()`r`n"
        "       `$LogName = `"Application`"`r`n"
        "       `$ScriptPath = `$MyInvocation.MyCommand.Path`r`n"
        "       `$Username = `$env:USERDOMAIN + `"\`" + `$env:USERNAME`r`n"
        "`r`n"
        "       New-EventLog -Source `$ScriptName -LogName `$LogName -ErrorAction SilentlyContinue`r`n"
        "`r`n"
        "       `$Message = `"Script: `" + `$ScriptPath + `"``nScript User: `" + `$Username + `"``nStarted: `" + (Get-Date).toString()`n"
        "       Write-EventLog -LogName `$LogName -Source `$ScriptName -EventID `"104`" -EntryType `"Information`" -Message `$Message`r`n"
        "`r`n"
        "       #	Dotsource in the functions you need.`r`n"
        "       }`r`n"
        "Process`r`n"
        "   {`r`n"
        "       }`r`n"
        "End`r`n"
        "   {`r`n"
        "       `$Message = `"Script: `" + `$ScriptPath + `"``nScript User: `" + `$Username + `"``nFinished: `" + (Get-Date).toString()`n"
        "       Write-EventLog -LogName `$LogName -Source `$ScriptName -EventID `"104`" -EntryType `"Information`" -Message `$Message	`r`n"
        "       }`r`n")
        if ($InstallMenu)
        {
            Write-Verbose "Try to install the menu item, and error out if there's an issue."
            try
            {
                $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("New blank script",{New-Script},"Ctrl+Alt+S") | Out-Null
                }
            catch
            {
                Return $Error[0].Exception
                }
            }

        }
    Process
    {
        if (!$InstallMenu)
        {
            Write-Verbose "Don't create a script if we're installing the menu"
            try
            {
                Write-Verbose "Create a new blank tab for the script"
                $NewScript = $psISE.CurrentPowerShellTab.Files.Add()
                Write-Verbose "Create a new empty script, return an error if there's an issue."
                $NewScript.Editor.InsertText($TemplateScript)
                $NewScript.Editor.InsertText(($NewScript.Editor.Select(22,1,22,2) -replace " ",""))
                $NewScript.Editor.InsertText(($NewScript.Editor.Select(26,1,26,2) -replace " ",""))
                $NewScript.Editor.InsertText(($NewScript.Editor.Select(40,1,40,2) -replace " ",""))
                $NewScript.Editor.InsertText(($NewScript.Editor.Select(43,1,43,2) -replace " ",""))
                $NewScript.Editor.Select(1,1,1,1)
                if ($ScriptName.Substring(($ScriptName.Length)-4,4) -ne ".ps1")
                {
                    $ScriptName += ".ps1"
                    }
                Write-Verbose "Change encoding from Unicode BigEndian to ASCII"
                $psISE.CurrentFile.GetType().GetField("Encoding","NonPublic,Instance").SetValue($psISE.CurrentFile, [text.encoding]::ASCII)
                $NewScript.SaveAs("$((Get-Location).Path)\$($ScriptName)")
                }
            catch
            {
                Return $Error[0].Exception
                }
            }
        }
    End
    {
        Return $NewScript
        }
    }
Function New-Function
{
    <#
        .SYNOPSIS
            Create a new function
        .DESCRIPTION
            This function creates a new function that wraps the selected text inside
            the Process section of the body of the function.
        .PARAMETER SelectedText
            Currently selected code that will become a function
        .PARAMETER InstallMenu
            Specifies if you want to install this as a PSIE add-on menu
        .PARAMETER FunctionName
            This is the name of the new function.
        .EXAMPLE
            New-Function -FunctionName "New-ImprovedFunction"
            
            Description
            -----------
            This example shows calling the function with the FunctionName parameter
        .EXAMPLE
            New-Function -InstallMenu $true
            
            Description
            -----------
            Installs the function as a menu item.
        .NOTES
            FunctionName : New-Function
            Created by   : Jeff Patton
            Date Coded   : 09/13/2011 13:37:24
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#New-Function
    #>
    [CmdletBinding()]
    Param
        (
        $SelectedText = $psISE.CurrentFile.Editor.SelectedText,
        $InstallMenu,
        $FunctionName
        )
    Begin
    {
        $WikiPage = ($psISE.CurrentFile.DisplayName).Substring(0,($psISE.CurrentFile.DisplayName).IndexOf("."))
        $TemplateFunction = @(
        "Function $FunctionName`r`n"
        "{`r`n"
        "   <#`r`n"
        "       .SYNOPSIS`r`n"
        "       .DESCRIPTION`r`n"
        "       .PARAMETER`r`n"
        "       .EXAMPLE`r`n"
        "       .NOTES`r`n"
        "           FunctionName : $FunctionName`r`n"
        "           Created by   : $($env:username)`r`n"
        "           Date Coded   : $(Get-Date)`r`n"
        "       .LINK`r`n"
        "           https://code.google.com/p/mod-posh/wiki/$($WikiPage)#$($FunctionName)`r`n"
        "   #>`r`n"
        "[CmdletBinding()]`r`n"
        "Param`r`n"
        "    (`r`n"
        "    )`r`n"
        "Begin`r`n"
        "{`r`n"
        "    }`r`n"
        "Process`r`n"
        "{`r`n"
        "$($SelectedText)`r`n"
        "    }`r`n"
        "End`r`n"
        "{`r`n"
        "    }`r`n"
        "}")
        if ($InstallMenu)
        {
            Write-Verbose "Try to install the menu item, and error out if there's an issue."
            try
            {
                $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("New function",{New-Function},"Ctrl+Alt+S") | Out-Null
                }
            catch
            {
                Return $Error[0].Exception
                }
            }

        }
    Process
    {
        if (!$InstallMenu)
        {
            Write-Verbose "Don't create a function if we're installing the menu"
            try
            {
                Write-Verbose "Create a new empty function, return an error if there's an issue."
                $psISE.CurrentFile.Editor.InsertText($TemplateFunction)
                }
            catch
            {
                Return $Error[0].Exception
                }
            }
        }
    End
    {
        }
    }
Register-ObjectEvent -InputObject $psISE.CurrentPowerShellTab.Files CollectionChanged -Action{
    <#
        .SYNOPSIS
            This command register an event handler for new files created within the ISE
        .DESCRIPTION
            The default encoding for PowerShell ISE is Unicode BigEndian, for some unknown
            reason, and for those of us who use version control systems, like Subversion,
            may have come across those files being set as binary.

            I got around this issue by creating a function to change the RepoProps attribute,
            but this solution is much more elegant. Once executed, this handler waits for a new
            file to be created, once that happens, it immediately sets the Encoding property 
            to ASCII.
        .PARAMETER
        .EXAMPLE
        .NOTES
            Created by   : Richard Vantreas
            Date Coded   : 10/13/2011 12:06:31
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#Register-ObjectEvent
        .LINK
            http://poshcode.org/3000
    #>
    [CmdletBinding()]
    Param
        (
        )
    Begin
    {
        }
    Process
    {
        Write-Verbose "Iterate through ISEFile objects"
        $Event.Sender | foreach {
            Write-Verbose "Set private field which holds default encoding to ASCII"
            $_.GetType().GetField("Encodindg","Nonpublic,Instance").SetValue($_, [text.encoding]::ASCII)
            }
        }
    End
    {
        }
    }
Function Edit-File
{
    <#
        .SYNOPSIS
            Open files in specified editor.
        .DESCRIPTION
            This function will open one or more files, in the specified editor.
        .PARAMETER FileSpec
            The filepath to open
        .EXAMPLE
            Edit-File -FileSpec c:\powershell\*.ps1
        .NOTES
            Set $Global:POSHEditor in your $profile to the path of your favorite
            text editor or to C:\Windows\notepad.exe. If that variable is not set
            we'll try and open the file in the PowerShell ISE otherwise give
            the user a polite message telling them what to do.
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#Edit-File
    #>    
    Param
        (
        [Parameter(ValueFromPipeline=$true)]
        $FileSpec
        )
    Begin
    {
        $FilesToOpen = Get-ChildItem $Filespec
        }
    Process
    {
        Foreach ($File in $FilesToOpen)
        {
            Try
            {
                if ($POSHEditor -ne $null)
                {
                    Invoke-Expression "$POSHEditor $File"
                    }
                else
                {
                    $psISE.CurrentPowerShellTab.Files.Add($File.FullName)
                    }
                }
            Catch
            {
                if ((Get-Host).Name -eq 'Windows PowerShell ISE Host')
                {
                    Return $Error[0].Exception
                    }
                else
                {
                    $Message = "You appear to be running in the console. "
                    $Message += "Please set `$Global:POSHEditor equalto the "
                    $Message += "path of your favorite text editor. Such as "
                    $Message += "`$Global:POSHEditor = c:\windows\notepad.exe `r`n"
                    $Message += "You can access your profile by typing 'notepad `$profile'"
                    Return $Message
                    }
                }
            }
        }
    End
    {
        }
    }
Function Save-All
{
    <#
        .SYNOPSIS
            Save all unsaved files in the editor
        .DESCRIPTION
            This function will save all unsaved files in the editor
        .EXAMPLE
            Save-All
            
            Description
            -----------
            The only syntax for the command.
        .NOTES
            FunctionName : Save-All
            Created by   : jspatton
            Date Coded   : 02/13/2012 15:08:51
            
            Routinely I have a need to have open and be editing several files
            at once. Decided to write a function to save them all since there
            isn't one currently available.
        .LINK
            https://code.google.com/p/mod-posh/wiki/PSISELibrary#Save-All
    #>
    [CmdletBinding()]
    Param
        (
        )
    Begin
    {
        Write-Verbose "Check if we're in ISE"
        if ((Get-Host).Name -ne 'Windows PowerShell ISE Host')
        {
            Write-Verbose "Not in the ISE exiting."
            Return
            }
        }
    Process
    {
        Write-Verbose "Iterate through each tab"
        foreach ($PSFile in $psISE.CurrentPowerShellTab.Files)
        {
            Write-Verbose "Check if $($PSFile.DisplayName) is saved"
            if ($psfile.IsSaved -eq $false)
            {
                Write-Verbose "Saving $($PSFile.DisplayName)" 
                $PSFile.Save()
                }
            
            }
        }
    End
    {
        }
    }
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYUF/z8MoNE+uP94pzxEckjKR
# C5agggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFV1mu+abf1RLenz
# zc0qPJ+Sh60WMA0GCSqGSIb3DQEBAQUABIIBAFHVhVzFy0NRo7jtiq7QdVgeTroq
# Rx7EgxwCggo4msr2dU2WMqr6AfWL1hjz3T2F/sxpcM5l443UF5XYAgeKOA6oTz2/
# +JMz4fUPfvYSjoLfXXKcaR79jq9c7UnYQ+2fjoewHlpbj1BTVC67PJblkWGwbQWe
# wzggRfVpC8XOb1cJ1nHKg8tcTuIhAUmRnP2jvbNg+zxR4CKkVmCvTyt00VYS84vI
# pgDTQzqOfQ3JRY7tXRjVTgUftfJfMeW5admuQbZnxbRhQmQJTK2yNCtSSQFWkB+C
# 5mntv2N+EUej59y9qSiYE5b9Efe0U0NTYymkdrjC1sUAL3fUUMRzxyPGT2U=
# SIG # End signature block
