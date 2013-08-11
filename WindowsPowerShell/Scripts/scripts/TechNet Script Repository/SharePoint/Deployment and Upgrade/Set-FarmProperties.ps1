<#
.SYNOPSIS
       The purpose of this script is to set name/value pairs on the farm property bag. 
	   Values are read from/stored in an xml configuration file.
.DESCRIPTION
       The purpose of this script is to set name/value pairs on the farm property bag. 
	   Values are read from/stored in an xml configuration file. This is useful for 
	   storing farm wide environment variables. One use is to have scripts read farm 
	   variables and then scripts can run the same on production/qa/dev.
	   Perform a bulk download of this and other useful scripts with this batch downloader: 
	   http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66
	   
.EXAMPLE
.\Set-FarmProperties.ps1 -GenerateSampleConfigurationFile 
Generate a sample configuration file
.EXAMPLE
.\Set-FarmProperties.ps1 
Set farm properties

	   Output from sample normal run
	   PS C:\Users\sp_admin\Documents\MESGLab\scripts> .\Set-FarmProperties.ps1

           Set Farm Properties
__________________________________________________

  Setting Farm property name:UTFarm100 to value:<UTFarm100 Value>
  Setting Farm property name:UTFarm101 to value:<UTFFarm101 Value>
__________________________________________________

             All Farm properties 
__________________________________________________

Name                           Value
----                           -----
UTFarm100                      UTFarm100 Value
UTFarm101                      UTFFarm101 Value
__________________________________________________

.EXAMPLE
.\Set-FarmProperties.ps1 -DebugMode 
Run in debug mode


	   Output from sample debug run

PS C:\Users\sp_admin\Documents\MESGLab\scripts> .\Set-FarmProperties.ps1 -DebugMode 
Configuration file set to: Set-FarmProperties.config
Starting  main
<Configuration><configurationSection><FarmProperties><PropertyBag><property name="UTFarm100" value=
"UTFarm100 Value" /><property name="UTFarm101" value="UTFFarm101 Value" /></PropertyBag></FarmPrope
rties></configurationSection></Configuration>
Set-FarmProperties.config
Starting  setFarmProperties

           Set Farm Properties
__________________________________________________

  Set-FarmProperties.setFarmProperties() property name=UTFarm100 value=UTFarm100 Value
  Setting Farm property name:UTFarm100 to value:<UTFarm100 Value>
  Set-FarmProperties.setFarmProperties() property name=UTFarm101 value=UTFFarm101 Value
  Setting Farm property name:UTFarm101 to value:<UTFFarm101 Value>
__________________________________________________
Finished  setFarmProperties

             All Farm properties
__________________________________________________

Name                           Value
----                           -----
UTFarm100                      UTFarm100 Value
UTFarm101                      UTFFarm101 Value
__________________________________________________

Finished  main

.EXAMPLE
.\Set-FarmProperties.ps1 -ConfigurationFile .\Set-FarmProperties.config
Run using a specific config file
.LINK
http://gallery.technet.microsoft.com/scriptcenter/bbd7dc18-3677-45ba-b0c5-933336217a01
.NOTES
  File Name : Set-FarmProperties.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall and validate

param
  (
    [string]
    # Specifies whether the script should "install", "validate" or "uninstall". "install" is the default.
    $InstallMode="install",
	
    [switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
    
    [string]
    # Specifies confuguration file name. The default is "this script name".config. i.e. 
    # Set-FarmProperties.config
    $ConfigurationFile="", 
    
    [switch]
    # Specifies whether the script should generate a sample configuration file. If you specify this flag, 
    # the script will generate the file and exit.
    $GenerateSampleConfigurationFile
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

# reference: 
# This script: http://gallery.technet.microsoft.com/scriptcenter/bbd7dc18-3677-45ba-b0c5-933336217a01
# SPFarm Members http://technet.microsoft.com/en-us/library/microsoft.sharepoint.administration.spfarm_members.aspx


$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.'))
$debug = $false
$farm = get-SPFarm


function AddFarmProperty([string]$name, [string]$value)
{

  if ($name.length -gt 0 )
  { 
    if ($farm.Properties[$name])
    {
      $farm.Properties[$name] = $value
    }
    else
    {
      $farm.Properties.Add($name, $value)
    }
    $farm.update()
    # check to make sure the update was successful
    $checkval =  $farm.Properties[$name]
    if ($checkval -ne $value)
    {
	  write-host ( "  Failed setting Farm property:"+$propname +" to <"+$propvalue  +">" ) -Foregroundcolor Red
    }
    else
    {
	  write-host ( "  Set Farm property:"+$propname +" to <"+$propvalue  +">" ) -Foregroundcolor Green
    }
    
  }
  
}

Function FunctionGenerateSampleConfigurationFile()
{
    $funcname = "FunctionGenerateSampleConfigurationFile"
    if ($DebugMode) { "Starting  $funcname " }

"Writing file $configurationname.config"
$selfdocumentingxml = @" 
<Configuration>
  <configurationSection>
      <FarmProperties> 
       <PropertyBag>
          <property name="UTFarm100" value="UTFarm100 Value"/>
          <property name="UTFarm101" value="UTFarm101 Value"/>
        </PropertyBag>
      </FarmProperties>       
  </configurationSection>
 </Configuration>
"@ | Out-File "$configurationname.config"
    if ($DebugMode) { "Finished $funcname " }

} 

Function setFarmProperties([xml]$thedata)
{

    $funcname = "setFarmProperties"
    if ($DebugMode) { write-host ("Starting  $funcname" ) -Foregroundcolor Green }

    # handle all Properties
    $props = $thedata.SelectNodes("Configuration/configurationSection/FarmProperties/PropertyBag/property")

    if(!$props -or $props -eq $null -or $props.length -eq 0)
    {
          "No properties to set"
    }
   write-host ("`n           Set Farm Properties " ) -Foregroundcolor Yellow 
   write-host ("__________________________________________________`n" ) -Foregroundcolor Yellow 

          
	foreach ($prop in $props)
	{      
      $propname = $prop.name
      $propvalue = $prop.value
      
      if ($DebugMode) { "  $configurationname.setFarmProperties() property name="+$propname +" value="+$propvalue  }
	  write-host ( "  Setting Farm property:"+$propname +" to <"+$propvalue  +">" ) 
      
	  AddFarmProperty $propname $propvalue
      
    }
    
	write-host ("__________________________________________________" ) -Foregroundcolor Yellow 

    if ($DebugMode) { write-host ("Finished  $funcname" ) -Foregroundcolor Red }

}



Function main([string]$ConfigurationFile)
{
    $funcname = "main"
    if ($DebugMode) { write-host ("Starting  $funcname" ) -Foregroundcolor Green }


	# check to make sure the file exists
	if(!(test-path $ConfigurationFile)){"Configuration file $ConfigurationFile not found";break}


    [xml]$xmldata = [xml](Get-Content $ConfigurationFile)
    if($DebugMode)
    {
      $xmldata.get_InnerXml()
      $ConfigurationFile
	}

    setFarmProperties $xmldata
    
   write-host ("`n             All Farm properties " ) -Foregroundcolor Yellow 
   write-host ("__________________________________________________" ) -Foregroundcolor Yellow 

   $farm.Properties.GetEnumerator() | sort Name
   write-host ("__________________________________________________`n" ) -Foregroundcolor Yellow 
   
    
    if ($DebugMode) { write-host ("Finished  $funcname" ) -Foregroundcolor Red }
	
	
}


if($ConfigurationFile.length -eq 0)
{
  $ConfigurationFile = "$configurationname.config"
    if ($DebugMode) { write-host ("Configuration file set to: $ConfigurationFile" )  }
	
}

""
"	   Perform a bulk download of this and other useful scripts with this batch downloader: "
"	   http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66"
""

if($GenerateSampleConfigurationFile)
{
  FunctionGenerateSampleConfigurationFile
}
else
{
  main $ConfigurationFile
}


