<#
.SYNOPSIS
       The purpose of this script is to create/delete crawled properties, managed properties, crawled property catagories, 
       and property mappings. The script will also generate a sample configuration file as a starting point.
.DESCRIPTION
       The purpose of this script is to create/delete crawled properties, managed properties, crawled property catagories, 
       and property mappings. The script will also generate a sample configuration file as a starting point.
.EXAMPLE
.\Maintain-FASTSearchMetadataProperties.ps1 -GenerateSampleConfigurationFile 
Generate a sample configuration file
.EXAMPLE
.\Maintain-FASTSearchMetadataProperties.ps1 -InstallMode uninstall
Delete crawled properties, managed properties, crawled property catagories, and property mappings
.EXAMPLE
.\Maintain-FASTSearchMetadataProperties.ps1 
Create crawled properties, managed properties, crawled property catagories, and property mappings
.LINK
http://gallery.technet.microsoft.com/ScriptCenter
.NOTES
  File Name : Maintain-FASTSearchMetadataProperties.ps1
  Author    : Brent Groom, Aaron Grant, Manoj Faria
#>

param
  (
    [string]
    # Specifies whether the script should "install" or "uninstall". "install" is the default.
    $InstallMode="install",
    
    [switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
    
    [string]
    # Specifies confuguration file name. The default is "this script name".config. i.e. 
    # Maintain-FASTSearchMetadataProperties.config
    $ConfigurationFile="", 
    
	[string]$directoryForConfigFile=$pwd.Path,

    [switch]
    # Specifies whether the script should generate a sample configuration file. If you specify this flag, 
    # the script will generate the file and exit.
    $GenerateSampleConfigurationFile
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

# reference: 
# MSDN – Managed properties: http://msdn.microsoft.com/en-us/library/ff464344.aspx#schema_managed_property 
# Technet – Index schema cmdlets: http://technet.microsoft.com/en-us/library/ff393787.aspx 
# MSDN - Crawled property methods – 
# http://msdn.microsoft.com/en-us/library/microsoft.sharepoint.search.extended.administration.schema.crawledproperty_methods.aspx


$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.'))
$debug = $false

Function FunctionGenerateSampleConfigurationFile()
{
    $funcname = "FunctionGenerateSampleConfigurationFile"
    if ($DebugMode) { "Starting  $funcname " }

"Writing file $configurationname.config"
$selfdocumentingxml = @" 
<Configuration>
  <configurationSection>
      <fastManagedProperties> 
        <!-- Valid types: 1=Text, 2=Integer, 3=Boolean, 4=Float, 5=Decimal, 6=Datetime-->
        <!-- This is an example showing what each configurable property means
        <mproperty name="referencemanagedproperty" type="1">
          <property name="RefinementEnabled">1</property>
          <property name="Queryable">1</property>
          <property name="SortableType">1</property>
          <property name="MergeCrawledProperties">1</property> 
          Include values from all crawled properties mapped. All multi valued fields must have this value set to 1. 
          For example all taxonomy fields
          <property name="MergeCrawledProperties">0</property> 
          Include values from a single crawled property based on the order specified.
        </mproperty>
      -->
        <mproperty name="mpfasttaxonomy1" type="1">
          <property name="RefinementEnabled">1</property>
          <property name="Queryable">1</property>
          <property name="SortableType">1</property>
          <property name="MergeCrawledProperties">1</property>
        </mproperty>

        <mproperty name="mpfastxmlmapper1" type="1">
          <property name="RefinementEnabled">1</property>
          <property name="Queryable">1</property>
          <property name="SortableType">1</property>
          <property name="MergeCrawledProperties">1</property>
        </mproperty>

      </fastManagedProperties> 
      
      <fastCrawledProperties>

        <CrawledProperty propertyName="cpfasttaxonomy1" propertySet="e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2" varType="31"/>
        <CrawledProperty propertyName="cpfastxmlmapper1" propertySet="e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2" varType="31"/>

      </fastCrawledProperties>
      
      <fastCrawledPropertyCategories>
        <category name="FASTDebug" propset="e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2" MapToContents="1" DiscoverNewProperties="1"/>
        <category name="JDBC" propset="4cc9f20a-c782-4c48-8961-c5356f8dff89" MapToContents="1" DiscoverNewProperties="1"/>
      </fastCrawledPropertyCategories>
      
      <fastMappings>

        <!-- FAST Debug mappings -->
        <mapping fastManagedProperty="mpfastxmlmapper1"           fastCrawledProperty="cpfastxmlmapper1" />
        <mapping fastManagedProperty="mpfasttaxonomy1" 	          fastCrawledProperty="cpfasttaxonomy1"  /> 
        
      </fastMappings>
      
  </configurationSection>
 </Configuration>
"@ | Out-File "$directoryForConfigFile\$configurationname.config"
    if ($DebugMode) { "Finished $funcname " }

} 

# TODO split this into two functions. One for check if changed and one to change.
Function setProperty($objin, $propertyName, $propertyValue)
{
    $funcname = "setProperty"
    if ($DebugMode) { "Starting  $funcname " }

    $propertyChanged = $false
    $fname = "$configurationname setProperty"
    #if($debug) {$fname+" objin="+$objin+" propertyName="+$propertyName+" propertyValue="+$propertyValue;$objin}
    $oldvalue = $objin.$propertyName
    if($oldvalue -is [bool])
    {
	    
        if($propertyvalue -eq "True")
        {            
		    if ($oldvalue -ne $true)
			{
			  $propertyChanged = $true
              $objin.$propertyName = $true;
			}
        }
        elseif($propertyvalue -eq "False")   
        {
		    if ($oldvalue -ne $false)
			{
			  $propertyChanged = $true
              $objin.$propertyName = $false;                            
			}
        }
        else
        {
		    
            $intpropertyvalue = [int]$propertyvalue
            $boolvalue = [bool]$intpropertyvalue;                        
		    if ($oldvalue -ne $boolvalue)
			{
			  $propertyChanged = $true
              $objin.$propertyName = $boolvalue;             
			}
        }
    }
    else
    {
      if ($oldvalue -ne $propertyValue)
	  {
		$propertyChanged = $true
        $objin.$propertyName = $propertyValue;
	  }

    }
    if ($DebugMode) { "Finished $funcname " }

	return $propertyChanged
}


Function removeFASTCrawledPropertyCategory([xml]$thedata)
{
    $funcname = "removeFASTCrawledPropertyCategory"
    if ($DebugMode) { "Starting  $funcname " }
	

    # handle all the FAST Crawled Properties
    $fastcats = $thedata.SelectNodes("Configuration/configurationSection/fastCrawledPropertyCategories/category")
    if ($DebugMode) { "Starting managaFASTCrawledPropertyCategory: "+$fastcats }
        
	foreach ($fastcat in $fastcats)
	{      
      $catname = $fastcat.name
      if ($DebugMode) { "catname: "+$catname }

      $category = Get-FASTSearchMetadataCategory -name $catname

	  $category.DeleteUnmappedProperties()      
      "Deleted unmapped Crawled Properties in Catagory:$catname"

      if ($DebugMode) { "$configurationname removeFASTCrawledPropertyCategory"  }
    }
    if ($DebugMode) { "Finished $funcname " }

}

Function manageFASTCrawledPropertyCategory([xml]$thedata)
{   
    $funcname = "manageFASTCrawledPropertyCategory"
    if ($DebugMode) { "Starting  $funcname " }


    if ($InstallMode -eq "uninstall" )
    {
      return
    }

    # handle all the FAST Crawled Properties
    $fastcats = $thedata.SelectNodes("Configuration/configurationSection/fastCrawledPropertyCategories/category")
    if ($DebugMode) { "Starting manageFASTCrawledPropertyCategory: "+$fastcats }
    if(!$fastcats -or $fastcats -eq $null -or $fastcats.length -eq 0)
    {
          "No categories to manage"
    }
        
	foreach ($fastcat in $fastcats)
	{      
      $catname = $fastcat.name
      if ($DebugMode) { "catname: "+$catname }
      
      $catid = $fastcat.propset
	  $maptocontents = $fastcat.MapToContents -eq '1'
	  $discovernewprops = $fastcat.DiscoverNewProperties -eq '1'

      # get the category
      $catobj = Get-FASTSearchMetadataCategory -name $catname -erroraction SilentlyContinue
      if(!$catobj)
      {
        $catobj = New-FASTSearchMetadataCategory -name $catname -Propset $catid
        "Created FASTSearchMetadataCategory $catname"
      }

      Set-FASTSearchMetadataCategory -name $catname -MapToContents $maptocontents -DiscoverNewProperties $discovernewprops

      if ($DebugMode) { "$configurationname manageFASTCrawledPropertyCategory: FAST Category name="+$catname  }
    }
    if ($DebugMode) { "Finished $funcname " }


}

Function manageFASTCrawledProperties([xml]$thedata)
{
    # <CrawledProperty varType="31" propertyName="url" propertySet="11280615-f653-448f-8ed8-2915008789f2" /> 

    $funcname = "manageFASTCrawledProperties"
    if ($DebugMode) { "Starting  $funcname " }

    if ($InstallMode -eq "uninstall" )
    {
      return
    }

    # handle all the FAST Crawled Properties
    $fastcps = $thedata.SelectNodes("Configuration/configurationSection/fastCrawledProperties/CrawledProperty")
        
	foreach ($fastcp in $fastcps)
	{      
	  $cpobj = $null
      $cpname = $fastcp.propertyName
      $cppropset = $fastcp.propertySet
	  $cpvarianttype = $fastcp.varType

      # get the property - using Set-FASTSearchMetadataCrawledProperty ensures that a single crawledprop object is returned
      trap {write-host ("Creating Crawled property $cpname " ) -Foregroundcolor Green; Continue}
      $cpobj = Set-FASTSearchMetadataCrawledProperty -name $cpname -varianttype $cpvarianttype -propset $cppropset -ErrorVariable err -erroraction SilentlyContinue 
      
      if(!$cpobj)
      {
        # TODO handle all the different variant types
        # apparently all properties can be multivalued. you cannot set this variable as it is not used... -IsMultiValued 1
        $cpobj = New-FASTSearchMetadataCrawledProperty -name $cpname -Propset $cppropset -VariantType $cpvarianttype
        "Created FASTSearchMetadataManagedCrawledProperty $cpname"
      }
      if ($DebugMode) { "$configurationname mainwork: FAST Crawled Property name="+$cpname  }
    }
    if ($DebugMode) { "Finished $funcname " }

}

# TODO handle all the different types
# TODO handle changing the type delete/add
Function ManageFASTManagedProperties([xml]$thedata)
{
    $funcname = "ManageFASTManagedProperties"
    if ($DebugMode) { "Starting  $funcname " }

    $fastmps = $thedata.SelectNodes("Configuration/configurationSection/fastManagedProperties/mproperty")
    
    #manage-FASTManagedProperties
    # handle all the FAST Managed Properties
	foreach ($fastmp in $fastmps)
	{
      $mpname = $fastmp.name
      
      if ($InstallMode -eq "uninstall" -or $InstallMode -eq "reinstall")
      {
	    $mptodel = Get-FASTSearchMetadataManagedProperty -name $mpname 
		if ($mptodel -ne $NULL)
		{
          Remove-FASTSearchMetadataManagedProperty -name $mpname -Force
		  "Removed FASTSearchMetadataManagedProperty $mpname"
	    }  
		else
		{
		  "Managed Property doesn't exist or was previously removed $mpname"
		}
        
      }
      if ($InstallMode -eq "uninstall" )
      {
        continue
      }
      # get the property
      $mpobj = Get-FASTSearchMetadataManagedProperty -name $mpname
      if(!$mpobj)
      {
        $mptype = $fastmp.type
        $mpobj = New-FASTSearchMetadataManagedProperty -name $mpname -type $mptype
        write-host ("Created managed property $mpname" ) -Foregroundcolor Green
      }
	  $changed = $false
      foreach ($prop in $fastmp.property)
      {
       
        $propname = $prop.name
        # type is a readonly property so continue. TODO have setProperty handle readonly properties
        if($propname -eq "type")
        {
          continue
        }
        $propval = $prop.get_InnerText()
        #if($DebugMode){"value before setProperty="+$mpobj.$propname}
		$changed = setProperty $mpobj $propname $propval
        #if($DebugMode){"value after setProperty="+$mpobj.$propname}
      }

	  if($changed)
	  {
        $mpobj.update()        
		write-host ("Updated managed property $mpname") -Foregroundcolor Green
      }
	  else
	  {
	  write-host ("No changes to managed property $mpname " ) -Foregroundcolor Green 
	  }
      if ($DebugMode) { "$configurationname ManageFASTManagedProperties: FAST Managed Property name="+$mpname  }
    
    }
    if ($DebugMode) { "Finished $funcname " }

}

#TODO remove the mappings
Function manageFASTMappings([xml]$thedata)
{
    $funcname = "manageFASTMappings"
    if ($DebugMode) { "Starting  $funcname " }

	if ($InstallMode -eq "uninstall" )
    {
	  return    
    }      

    # setup the property mappings
    $fastmappings = $thedata.SelectNodes("Configuration/configurationSection/fastMappings/mapping")
    
    foreach ($fastmap in $fastmappings)
    {
      $mpobj = $NULL
      $cpobj = $NULL
	  $position = $NULL
      
      $mpname = $fastmap.fastManagedProperty
	  $cpname = $fastmap.fastCrawledProperty
	  $position = $fastmap.position
      $mpobj = Get-FASTSearchMetadataManagedProperty -name $fastmap.fastManagedProperty
      $cpobj = Get-FASTSearchMetadataCrawledProperty -name $fastmap.fastCrawledProperty -erroraction SilentlyContinue
	  if ($mpobj -eq $NULL)
	  {
	    "manageFASTMapping: Managed Property $mpname doesn't exist"
	  }
	  if ($cpobj -eq $NULL)
	  { 
	    "manageFASTMapping: Crawled Property $cpname doesn't exist"
	  }
	  if ($mpobj -eq $NULL -or $cpobj -eq $NULL)
	  {
	   continue
	  }
      # See if this mapping already exists
      $mplist = $cpobj.GetMappedManagedProperties()
      $alreadymapped = $false
      foreach ($mp in $mplist)
      {
        if ( $mpname -eq $mp.name)
        {
          $alreadymapped = $true
        }
      }
      if(!$alreadymapped)
      {
	    "Creating new mapping: $cpname -> $mpname"
        if ($position -eq 'last')
		{
			# this inserts at the end of the list
			New-FASTSearchMetadataCrawledPropertyMapping -ManagedProperty $mpobj -CrawledProperty $cpobj
		}
		else
		{
	        #this inserts at the beginning of the list
		    $cplistfromMP = $mpobj.GetCrawledPropertyMappings()
			$cplistfromMP.Insert(0,$cpobj)
			$mpobj.SetCrawledPropertyMappings($cplistfromMP)
		}
      }
    }
    if ($DebugMode) { "Finished $funcname " }

}

Function removeFASTMappings([xml]$thedata)
{
    $funcname = "removeFASTMappings"
    if ($DebugMode) { "Starting  $funcname " }

    # setup the property mappings
    $fastmappings = $thedata.SelectNodes("Configuration/configurationSection/fastMappings/mapping")
    
    foreach ($fastmap in $fastmappings)
    {
      $mpobj = $NULL
      $cpobj = $NULL
      
      $mpname = $fastmap.fastManagedProperty
	  $cpname = $fastmap.fastCrawledProperty
      $mpobj = Get-FASTSearchMetadataManagedProperty -name $fastmap.fastManagedProperty
      $cpobj = Get-FASTSearchMetadataCrawledProperty -name $fastmap.fastCrawledProperty -erroraction SilentlyContinue

	  if ($mpobj -ne $NULL -and $cpobj -ne $NULL)
	  {
	    "Removing Mapping cp:$cpname mp:$mpname"
		Remove-FASTSearchMetadataCrawledPropertyMapping -CrawledProperty $cpobj -ManagedProperty $mpobj -Force:$true
	  }
	  else
	  {	   
	    "Mapping does not exist for Managed Property:" + $fastmap.fastManagedProperty + " and Crawled Property:" + 
        $fastmap.fastCrawledProperty
	  }
    }
    if ($DebugMode) { "Finished $funcname " }


}

Function main([string]$ConfigurationFile)
{
    $funcname = "main"
    if ($DebugMode) { "Starting  $funcname " }


    [xml]$xmldata = [xml](Get-Content $ConfigurationFile)
    if($DebugMode)
    {
      $xmldata.get_InnerXml()
      $ConfigurationFile
	}
    
	if ($InstallMode -eq "uninstall" -or $InstallMode -eq "reinstall")
    {
	  removeFASTMappings $xmldata
    }      

	manageFASTCrawledPropertyCategory $xmldata

    manageFASTCrawledProperties $xmldata

    manageFASTManagedProperties $xmldata
    
    manageFASTMappings $xmldata

    if ($InstallMode -eq "uninstall" )
    {
        removeFASTCrawledPropertyCategory $xmldata
    }      


    # TODO optimize the gets and store the objects in a hash so we don't have to get them again
    if ($DebugMode) { "Finished $funcname " }
    
}


if($ConfigurationFile.length -eq 0)
{
  $ConfigurationFile = "$configurationname.config"
}

if($GenerateSampleConfigurationFile)
{
  FunctionGenerateSampleConfigurationFile
}
else
{
  main $ConfigurationFile
}



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhoSrCLCVmyDg2V1qQEBwOv94
# ODKgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKyQGOuccA4lQTnN
# 6WiCVGkHCxTSMA0GCSqGSIb3DQEBAQUABIIBANNQqe0xf9OMH2JjTZJWKPyVex1U
# qDgOZh0+O9Q85SwGfc0pDZYNz48GX2Hj891f6Dyunzjb8jSZYGRaNa9CIsVNIa8l
# VTbot2XOryQF14cG848m0Rn9a7m9aGDBLn4KhehBVTZHA4MOjna5Hwc1heKwHf68
# 1JYQsXH/o9fW7x3Hr7drotnDgXpGF/9qbDmYsiTxEBeR0gDCExNTFQ7Jj/n42wER
# G/F9cR8+QW3wBfYDKpURstYlKJfleRwxJB0LXmtIHUA2etI4bRvaPL5br1whwfcW
# jDaJ3loDsRoE7BALFGOQh8WTK4jcFYb0pQzb7CjrBfYIKxFwUNx0d3FpRLs=
# SIG # End signature block
