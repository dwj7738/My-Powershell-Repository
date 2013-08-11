function Get-Installed 
{
      <#
  .SYNOPSIS
    This function lists data found in the registry associated with installed programs.
  .DESCRIPTION
  Describe the function in more detail
  Author: Stan Miller
  .EXAMPLE
    Get all apps whose display names start with a specific string and display all valuenames
  get-installed -re "^microsoft xna" -valuenameRE ".*"
        The "^" above means starts with the following string.
        The ".*" means match all including the empty string
  .EXAMPLE
  get-installed -re "^microsoft xna game studio platform tool$"
        Display the default set of valuenames for apps whose displayname starts (^) and ends ($) with "microsoft xna game studio platform tool"

displayname=microsoft xna game studio platform tools
           displayversion=1.1.0.0
           installdate=20100204
           installsource=C:\Program Files (x86)\Microsoft XNA\XNA Game Studio\v3.1\Setup\
           localpackage=C:\Windows\Installer\2d09d3a5.msi
           madeup-gname={BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
           madeup-loginid=System
           madeup-wow=1
           uninstallstring=MsiExec.exe /I{BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
           windowsinstaller=1

  .EXAMPLE
  get-installed -re "^microsoft xna game studio platform tool" -compress $False
        Display the default set of valuenames for apps whose displayname starts with "^microsoft xna"
        only this time show all registry sources. In this case the products and uninstall areas

displayname=microsoft xna game studio platform tools
      keypath=software\microsoft\windows\currentversion\installer\userdata\s-1-5-18\products\ceec4debf3683ba4ab324571462e2dec\installproperties
           displayversion=1.1.0.0
           installdate=20100204
           installsource=C:\Program Files (x86)\Microsoft XNA\XNA Game Studio\v3.1\Setup\
           localpackage=C:\Windows\Installer\2d09d3a5.msi
           madeup-loginid=System
           uninstallstring=MsiExec.exe /I{BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
           windowsinstaller=1
      keypath=software\wow6432node\microsoft\windows\currentversion\uninstall\{bed4ceec-863f-4ab3-ba23-541764e2d2ce}
           displayversion=1.1.0.0
           installdate=20100204
           installsource=C:\Program Files (x86)\Microsoft XNA\XNA Game Studio\v3.1\Setup\
           madeup-gname={BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
           madeup-wow=1
           uninstallstring=MsiExec.exe /I{BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
           windowsinstaller=1

  .EXAMPLE
  get-installed -namesummary $true
        Display the frequency of valuenames for all apps in all registry location
        only this time show all registry sources
        in reverse order of occurrence.

UninstallString,616
DisplayName,616
Publisher,600
DisplayVersion,525
VersionMajor,490
InstallDate,474
EstimatedSize,474
InstallSource,470
Version,469
ModifyPath,461
WindowsInstaller,457
Language,396
madeup-gname,391
NoModify,366
HelpLink,323
madeup-wow,308
NoRepair,256
SystemComponent,235
LocalPackage,225
URLInfoAbout,171
VersionMinor,167
InstallLocation,159
ParentDisplayName,91
ParentKeyName,91
madeup-native,83
DisplayIcon,79
Comments,78
URLUpdateInfo,71
RegOwner,69
MoreInfoURL,66
ProductID,62
RegCompany,59
NoRemove,53
Readme,35
Contact,33
ReleaseType,26
IsMinorUpgrade,26
RegistryLocation,25
HelpTelephone,21
UninstallPath,16
LogFile,9
MajorVersion,7
APPName,6
MinorVersion,6
Size,6
QuietUninstallString,5
NoElevateOnModify,4
Inno Setup: User,3
SkuComponents,3
ShellUITransformLanguage,3
ProductGuid,3
NVI2_Package,3
Inno Setup: App Path,3
Inno Setup: Icon Group,3
CacheLocation,3
ProductCodes,3
NVI2_Timestamp,3
Inno Setup: Deselected Tasks,3
NVI2_Setup,3
Inno Setup: Setup Version,3
LogMode,3
PackageIds,3
Inno Setup: Language,2
RequiresIESysFile,2
InstanceId,2
UninstDataVerified,1
BundleVersion,1
BundleProviderKey,1
Inno Setup: Selected Components,1
FCLAppName,1
Inno Setup: Selected Tasks,1
Integrated,1
BundleUpgradeCode,1
Installed,1
SQLProductFamilyCode,1
FCLGUID,1
UninstallerCommonDir,1
BundleDetectCode,1
InstallerType,1
DisplayName_Localized,1
Inno Setup: Setup Type,1
EngineVersion,1
BundleCachePath,1
Resume,1
 .EXAMPLE
  get-installed -re "^microsoft xna game studio platform tools$" -makeobjects $true
  Instead of displaying the valuenames create an object for further use

  displayname          : microsoft xna game studio platform tools
  DisplayVersion       : 1.1.0.0
  InstallDate          : 20100204
  InstallLocation      :
  InstallSource        : C:\Program Files (x86)\Microsoft XNA\XNA Game Studio\v3.1\Setup\
  LocalPackage         : C:\Windows\Installer\2d09d3a5.msi
  madeup-gname         : {BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
  madeup-native        :
  madeup-wow           : 1
  QuietUninstallString :
  UninstallString      : MsiExec.exe /I{BED4CEEC-863F-4AB3-BA23-541764E2D2CE}
  WindowsInstaller     : 1

 .EXAMPLE
  get-installed -re "^microsoft xna game studio" -makeobjects $true|format-table
  Instead of displaying the valuenames create an object for further use


displayname         DisplayVersion      InstallDate         InstallLocation     InstallSource       LocalPackage        madeup-gname        madeup-native                madeup-wow QuietUninstallStrin
                                                                                                                                                                                    g
-----------         --------------      -----------         ---------------     -------------       ------------        ------------        -------------                ---------- -------------------
microsoft xna ga... 3.1.10527.0                                                                                         XNA Game Studio 3.1                                       1
microsoft xna ga... 3.1.10527.0         20100204                                c:\c3aa2d4649aa0... c:\Windows\Insta... {E1D78366-91DA-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                C:\Program Files... C:\Windows\Insta... {007BECB0-17DD-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                c:\c3aa2d4649aa0... c:\Windows\Insta... {0DC16794-7E69-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                C:\Program Files... C:\Windows\Insta... {AF9BDE67-11A5-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                C:\Program Files... C:\Windows\Insta... {3BA37E38-B53D-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                C:\Program Files... C:\Windows\Insta... {DFB81F19-ED3A-4...                                       1
microsoft xna ga... 3.1.10527.0         20100204                                C:\Program Files... C:\Windows\Insta... {7FD30AE7-281D-4...                                       1
microsoft xna ga... 1.1.0.0             20100204                                C:\Program Files... C:\Windows\Insta... {BED4CEEC-863F-4...                                       1



  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER re
  regular expression used to select software displayname
  .PARAMETER compress
  defaults to true. Merges values by valuename from many sources of installed data.
    The merge means if it finds a valuename more than once it shows only the first one found.
    This is true except for madeup-loginid. Instead a string is created with comma separated values
       where the values are the loginids of sids found in the product sections.
  Set to false the program will separate the values by registry keypath.
    data from products installed by the system takes precedence over software...uninstall
  .PARAMETER namesummary
  displays a list of valuenames found in registry in descending order of frequency
  no other data shown if this is set to $true
  .PARAMETER valuenameRE
  regular expression to specify which valuenames to display
  defaults to "displayversion|windowsinstaller|uninstallstring|localpackage|installsource|installdate|madeup-|gp_"
  specify .* to display all valuenames
    valuename not in registry but madeup in this program start with madeup-
      madeup-wow was set for uninstall key in the software wow6432node portion of the registry
      madeup-native was set for uninstall key in the software native portion of the key
      madeup-guid was set from the uninstall subkey containing the value names
      madeup-loginid was set from the registry product section
    valuename from group policy is prepended with "gp_"
  .PARAMETER makeobjects
    Create objects whose properties are the merged valuenames defined by the value name defaults. 
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$False)]
    [Alias('computer')]
    [string]$computername=$env:computername,
    [string]$re = ".*",
    [boolean]$compress=$true,
    [boolean]$namesummary=$false,
    [boolean]$makeobjects=$false,
    [string]$valuenameRE="displayversion|windowsinstaller|uninstallstring|installlocation|localpackage|installsource|installdate|madeup-|gp_",
    [string]$makeobjectsRE="displayversion|windowsinstaller|uninstallstring|installlocation|localpackage|installsource|installdate|madeup-|gp_"
  )

  begin {
    try
    {
        $regbase=[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$computername)
    }
    catch [Exception]
    {
        # see if remote registry is stopped
        Write-Host "Failed to open registry due to "  $_.Exception.Message
        if ($_.Exception.HResult -eq 53)
        {
            # The network path was not found
            exit
        }
        Write-Host "Checking if registry service started on "  $computername
        try
        {
            Get-Service remoteregistry -ComputerName $computername|gm
            $remoteregistry=(Get-Service remoteregistry -ComputerName $computername).status
        }
        catch [Exception]
        {
            Write-Host "cannot reach service manager on " $computername
            exit
        }
        "Remote Registry status is " + $remoteregistry
        if ($remoteregistry -ieq "stopped")
        {
	        Set-Service remoteregistry -Status Running -Computername $computername
	        sleep 5
            try
            {
                $regbase=[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$computername)
            }
            catch [Exception] 
            {
                return $_.Exception.Message
            }
        }
        else
        {
            write-Host  "could not open registry for "  $computername
            exit

        }
    }
    $software=@{} # Keep hash of software displaynames -> hash of keypaths -> hash of valuename->values
    $valuenamesfound=@{} # keep count of valuenames found
    $pg2displayname=@{} # set in getproductdata and used in getgrouppolicydata
    $sid2logid=@{}  # Set it
    $installedbywho=@{} # track who has installed a product
    Function load_sid2logid
    {
        # Set $sid2logid using registry profilelist
        $ProfileListKey=$regbase.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList",$False)
        if ($ProfileListKey -eq $null) {return "Yuck"}
        foreach ($guid in $ProfileListKey.GetSubKeyNames())
        {
            if ($guid -imatch "^s-")
            {
                switch($guid.ToUpper())
                {
                    "S-1-5-18" {$sid2logid.Add("S-1-5-18","System")}
                    "S-1-5-19" {$sid2logid.Add("S-1-5-19","Service")}
                    "S-1-5-20" {$sid2logid.Add("S-1-5-20","Network")}
                    default 
                    {
                        [string]$ProfileImagePath=$ProfileListKey.OpenSubKey($guid).GetValue("ProfileImagePath")
                        $logid=$ProfileImagePath.Split("\")[-1]
                        $sid2logid.Add($guid.ToUpper(),$logid)
                    }
                }

            }
        }
    }
    load_sid2logid
  }

  process 
  {

    Function upvaluenamesfound
    {
        param([string]$valuename)
        if ($valuenamesfound.ContainsKey($valuename))
        {
            $valuenamesfound.$valuename++
        }
        else
        {
            $valuenamesfound.Add($valuename,1)
        }
    }

    Function getuninstalldata
    {
        param([STRING] $subkeyname)
        $uninstallkey=$regbase.OpenSubKey($subkeyname,$False)
        foreach ($gname in $uninstallkey.GetSubKeyNames())
        {
            $prodkey=$uninstallkey.OpenSubKey($gname)
        
            $displayname=$prodkey.GetValue("displayname")
            $uninstallstring=$prodkey.GetValue("uninstallstring")
            if ($displayname -ine "" -and $displayname -ne $null  -and $uninstallstring -ine ""  -and $uninstallstring -ine $null )
            {
                $KeyPath=$subkeyname+"\"+$gname
                $valuehash= @{}
                #"KeyPath=" + $KeyPath
                #"displayname='" + $displayname + "'"
                $valuehash.Add("madeup-gname",$gname)
                upvaluenamesfound("madeup-gname")
                if ($subkeyname -imatch "wow6432node")
                {
                    $valuehash.Add("madeup-wow",1)
                    upvaluenamesfound("madeup-wow")
                }
                else
                {
                    $valuehash.Add("madeup-native",1)
                    upvaluenamesfound("madeup-native")
                }
                foreach ($valuename in $prodkey.GetValueNames())
                {
                    $value=$prodkey.GetValue($valuename)
                    if ($value -ine "" -and $value -ine $null)
                    {
                        $valuehash.Add($valuename.tolower(),$prodkey.GetValue($valuename))
                        upvaluenamesfound($valuename)
                        #"added " + $valuename + "=" + $valuehash.$valuename
                    }
                }
                $guidformat="no"
                if ($gname.StartsWith("{") -and $gname.EndsWith("}") -and $gname.Length -eq 38 ) {$guidformat="yes"} 
                $tolower=$displayname.ToLower()
                if ($software.ContainsKey($tolower))
                {
                    $software.$tolower.Add($KeyPath.ToLower(),$valuehash)
                }
                else
                {
                    $subhash=@{}
                    $subhash.Add($KeyPath.ToLower(),$valuehash)
                    $software.Add($tolower,$subhash)
                }
            }
        }
    }

    Function getproductdatabysid
    {
        param([string]$sid)
        $subkeyname="SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\"+$sid+"\Products"
        $productkey=$regbase.OpenSubKey($subkeyname,$False)
        foreach ($gname in $productkey.GetSubKeyNames())
        {
            $prodkey=$productkey.OpenSubKey($gname).OpenSubKey("InstallProperties")
            try
            {
                $displayname=$prodkey.GetValue("displayname")
                $uninstallstring=$prodkey.GetValue("uninstallstring")
                $pg2displayname.Add($gname.ToLower(),$displayname)  # remember packed guid
            }
            catch
            {
                $uninstallstring=""
                $displayname=""
            }
            if ($displayname -ine "" -and $displayname -ne $null  -and $uninstallstring -ine ""  -and $uninstallstring -ine $null )
            {
                $KeyPath=$subkeyname+"\"+$gname + "\InstallProperties"
                #"KeyPath=" + $KeyPath
                #"displayname='" + $displayname + "'"
                $valuehash= @{}
                $valuehash.Add("madeup-loginid",$sid2logid.$sid)
                foreach ($valuename in $prodkey.GetValueNames())
                {
                    $value=$prodkey.GetValue($valuename)
                    if ($value -ine "" -and $value -ine $null)
                    {
                        $valuehash.Add($valuename.tolower(),$prodkey.GetValue($valuename))      
                        upvaluenamesfound($valuename)
                        #"added " + $valuename + "=" + $valuehash.$valuename
                    }
                }
                $tolower=$displayname.ToLower()
                if ($software.ContainsKey($tolower))
                {
                    $software.$tolower.Add($KeyPath.ToLower(),$valuehash)
                }
                else
                {
                    $subhash=@{}
                    $subhash.Add($KeyPath.ToLower(),$valuehash)
                    $software.Add($tolower,$subhash)
                }
            }
        }
    }

    Function getproductdata
    {
        $subkeyname="SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData"
        $userdatakey=$regbase.OpenSubKey($subkeyname,$False)
        foreach ($sid in $userdatakey.GetSubKeyNames())
        {
            getproductdatabysid($sid)
        }
    }

    Function getgrouppolicydata
    {
        $subkeyname="SOFTWARE/Microsoft/Windows/CurrentVersion/Group Policy/AppMgmt"
        $gpkey=$regbase.OpenSubKey($subkeyname,$False)
        if ($gpkey -eq $null)
        {
            return
        }
        foreach ($gname in $gpkey.GetSubKeyNames())
        {
            $prodkey=$gpkey.OpenSubKey($gname)
            $displayname=$pg2displayname.($gname.ToLower())
            if ($displayname -ine "" -and $displayname -ine $null)
            {
                $keypath=$subkeyname+ "\" + $gname
                $valuehash=@{}
                foreach ($valuename in $prodkey.GetValueNames())
                {
                    $value=$prodkey.GetValue($valuename)
                    if ($value -ine "" -and $value -ine $null)
                    {
                        $valuehash.Add("gp_"+$valuename.tolower(),$prodkey.GetValue($valuename))      
                        upvaluenamesfound($valuename)
                        #"added " + $valuename + "=" + $valuehash.$valuename
                    }
                }
                $tolower=$displayname.ToLower()
                if ($software.ContainsKey($tolower))
                {
                    $software.$tolower.Add($KeyPath.ToLower(),$valuehash)
                }
                else
                {
                    $subhash=@{}
                    $subhash.Add($KeyPath.ToLower(),$valuehash)
                    $software.Add($tolower,$subhash)
                }
            }
        }
    }

    getuninstalldata("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    getuninstalldata("SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
    getproductdata
    getgrouppolicydata

    #HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00002109610090400000000000F01FEC\InstallProperties
    if ($namesummary)
    {
        $mykeys=$valuenamesfound.keys|sort-object -Property @{Expression={[int]$valuenamesfound.$_}; Ascending=$false}
        foreach ($valuename in ($mykeys))
        {
            if ($valuename -ne "" -and $valuename -ne $null) {$valuename + "," + $valuenamesfound.$valuename}
        }
    }
    elseif ($makeobjects)
    {
      foreach ($displayname in ($software.Keys|Sort-Object))
        {
            if ($displayname -imatch $re) {
                #" "
                #"displayname="  + $displayname
                $compressedhash=@{};
                foreach ($keypath in ($software.$displayname.Keys|Sort-Object))
                {
                    foreach ($valuename in ($software.$displayname.$keypath.Keys|Sort-Object))
                    {
                       if (-not $compressedhash.ContainsKey($valuename))
                       {
                            $compressedhash.Add($valuename,$software.$displayname.$keypath.$valuename)
                       }
                       elseif ($valuename -ieq "madeup-loginid")
                       {
                            $compressedhash.$valuename += ("," + $software.$displayname.$keypath.$valuename)
                       }
                    }
                }
                $obj=New-Object object
                $obj|Add-Member -MemberType NoteProperty "displayname"  $displayname
                foreach ($valuename in ($valuenamesfound.keys|Sort-Object))
                {
                    if ($valuename -imatch $makeobjectsRE)
                    {
                        if ($compressedhash.ContainsKey($valuename))
                        {
                            $obj|Add-Member -MemberType NoteProperty $valuename $compressedhash.$valuename
                        }
                        else
                        {
                            $obj|Add-Member -MemberType NoteProperty $valuename ""
                        }
                    }
                }
                Write-Output $obj
            }
        }
    }
    elseif ($compress)
    {
        foreach ($displayname in ($software.Keys|Sort-Object))
        {
            if ($displayname -imatch $re) {
                " "
                "displayname="  + $displayname
                $compressedhash=@{};
                foreach ($keypath in ($software.$displayname.Keys|Sort-Object))
                {
                    foreach ($valuename in ($software.$displayname.$keypath.Keys|Sort-Object))
                    {
                       if (-not $compressedhash.ContainsKey($valuename))
                       {
                            $compressedhash.Add($valuename,$software.$displayname.$keypath.$valuename)
                       }
                       elseif ($valuename -ieq "madeup-loginid")
                       {
                            $compressedhash.$valuename += ("," + $software.$displayname.$keypath.$valuename)
                       }
                    }
                }
                foreach ($valuename in ($compressedhash.Keys|Sort-Object))
                {
                    if ($valuename -imatch $valuenameRE)
                    {
                        "           " + $valuename +  "=" +  $compressedhash.$valuename
                    }
                }
            }
        }
    }
    else
    {
        foreach ($displayname in ($software.Keys|Sort-Object))
        {
            if ($displayname -imatch $re) {
                " "
                "displayname="  + $displayname
                foreach ($keypath in ($software.$displayname.Keys|Sort-Object))
                {
                    "      keypath=" + $keypath
                    foreach ($valuename in ($software.$displayname.$keypath.Keys|Sort-Object))
                    {
                        if ($valuename -imatch $valuenameRE)
                        {
                            "           " + $valuename +  "=" +  $software.$displayname.$keypath.$valuename
                        }
                    }
                }
            }
        }
    }
  }
}