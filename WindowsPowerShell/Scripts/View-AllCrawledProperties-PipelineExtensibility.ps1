#Contributors: Brent Groom, Aaron Grant
#New-FASTSearchMetadataCrawledProperty -Name cpproperty1 -Propset e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2 -VariantType 31

param([string]$inputfile, [string]$outputfile, [switch]$getFASTCrawledProperties, [switch]$deploy, [switch]$enabledebuglogging)

#TODO: implement an undeploy step
#TODO: create a copy of the pipelineextensibility.xml file before overwriting it
#TODO: Add help output to script for display on the command line

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

$thispsfile = $myinvocation.mycommand.name

#TODO: make these variables setable via command line parameters
$propertySet = "e80ee0e8-71c0-4d8d-b918-360ad2fd7aa2"
$varType = "31"
$propertyName = "cpproperty1"

$fastdir = $env:fastsearch
if($fastdir.EndsWith('\')) { $fastdir = $fastdir.substring(0,$fastdir.length-1) }
$psfile = "$fastdir\bin\View-AllCrawledProperties-PipelineExtensibility.ps1"

Function mainwork([string]$inputfile, [string]$outputfile)
{
    $locallowdir = "c:\Users\sp_admin\AppData\LocalLow\pipeline"
    $logfile = "$locallowdir\pipelineextensibility.log"
    
    $ext = Get-Date -format 'yyMMddhhmmss'  
    
    # Debug line to write output to a log file in the locallow directory
    if($enabledebuglogging){    Add-Content  $logfile "inputfile $outputfile $ext" }

    $copyofinputfile = "$locallowdir\$ext.input.xml"
    
    
    # Debug line to make a copy of the input file and place it in the locallow directory
    if($enabledebuglogging){    copy-item $inputfile $copyofinputfile }
    
    $pipelineextensibilityxmlfile = "$fastdir\etc\pipelineextensibility.xml";
    
    processDocument $inputfile $outputfile
    
}

Function processDocument([string]$infile, [string]$outfile)
{
    $xmldata = [xml](Get-Content $infile)

    $cps = $xmldata.SelectNodes("Document/CrawledProperty")
    $shortoutput = "<ul>"
    $detailedoutput = "<ul>"
        
	foreach ($cp in $cps)
	{      
      $cpvalue = $cp.get_InnerText()
      if($cpvalue.length -gt 0)
      {
        $cppropset = $cp.propertySet
        $cpname = $cp.propertyName
        $cptype = $cp.varType
        $cpid = $cp.propertyId
        if($cpname.length -gt 0) 
        { 
            $shortoutput += $("<li>" + $cpname +"=" + $cpvalue + "</li> ")
            $detailedoutput += $("<li>propertyName=" + $cpname +" propertyValue=" + $cpvalue + " propertySet=" + $cppropset + " varType=" + $cptype + "</li> " )
        }
        if($cpid.length -gt 0) 
        { 
            $shortoutput += $("<li>" + $cpid +"=" + $cpvalue + "</li> ")
            $detailedoutput += $("<li>propertyId=" + $cpid +" propertyValue=" + $cpvalue + " propertySet=" + $cppropset + " varType=" + $cptype + "</li> " )
        }
        
      }
    }
    $shortoutput += "</ul>"
    $detailedoutput += "</ul>"

    $outputxml = @" 
<Document>
  <CrawledProperty propertySet="$propertySet" varType="$varType" propertyName="$propertyName"><![CDATA[$shortoutput $detailedoutput]]></CrawledProperty>
  </Document>
"@ | Out-File "$outfile"

   $copyofoutputfile = "$locallowdir\$ext.output.xml"
   
   # debugging line to place a copy of the output file in locallow directory
   if($enabledebuglogging){ copy-item $outfile $outdestfile }
   
   # debug line to write output to a log file in the locallow directory
   if($enabledebuglogging){ Add-Content  $logfile "$ext $outdestfile $shortoutput $detailedoutput" }

}

Function get-FASTCrawledProperties()
{
    $cps = Get-FASTSearchMetadataCrawledProperty

    $outstr="<PipelineExtensibility>`n"
    $outstr+="<Run command=""viewcps.bat %(input)s %(output)s "">`n"
    $outstr+="<Input>`n"

    # List of variant types: http://msdn.microsoft.com/en-us/library/cc237865(PROT.13).aspx
    # Another low level reference: http://msdn.microsoft.com/en-us/library/aa380072(VS.85).aspx
    
    # Official list of supported variant type mappings of FAST Search Server 2010 for SharePoint http://technet.microsoft.com/en-us/library/ff191231.aspx
    $arrPropertys = "2", "3", "4", "5", "6", "7", "11", "14", "16", "17", "18", "19", "20", "21", "22", "23", "64", "8", "30", "31", "72"
    $arrInvalidPropertyIds = "-2147483646"
    foreach ($cp in $cps)
    {
            #TODO: write out all variant types
            $thename=$cp.Name
            $isnum = $thename.ToLower().equals($thename.ToUpper())
            $attrPropertyStr = "propertyName"
            if($isnum)
            {
                $attrPropertyStr = "propertyId"            
            }
            
            # these variant types a known to fail during FAST document processing. Not sure what they do in SP search
            if ( $arrPropertys -contains $cp.VariantType -AND $arrInvalidPropertyIds -notcontains $cp.Name)
            {
                $outstr+="<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ " + $attrPropertyStr + "="""+$cp.Name+"""/>`n"            
            }
            else
            {
                $outstr+="<!-- Unknown Variant type -->`n <!--<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ propertyName="""+$cp.Name+"""/>-->`n"            
            }
    }
    
    $outstr+="<!-- special crawled properties for pipeline extensibility -->"
    $outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""url""/>"
    #$outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""body""/>"
    #$outstr+="<CrawledProperty propertySet=""11280615-f653-448f-8ed8-2915008789f2"" varType=""31"" propertyName=""data""/>"

    $outstr+="    </Input>`n"
    $outstr+="    <Output>`n"
    $outstr+="      <CrawledProperty propertySet=""$propertySet"" varType=""$varType"" propertyName=""$propertyName""/>`n"
    $outstr+="    </Output>`n"
    $outstr+="  </Run>`n"
    $outstr+="</PipelineExtensibility>`n"

    $outstr | Out-File pipelineextensibility.xml

    $viewcpsBatFile = 'powershell "' + $psfile + ' -inputfile %1 -outputfile %2 -enabledebuglogging $true"'
    $viewcpsBatFile | Out-File "viewcps.bat" -encoding ASCII
    
}

Function install-debugPipelineExtensibility ()
{
    #TODO: create a debug crawled property / managed property mapping

    
    $mc = Get-FASTSearchMetadataCategory -Name FASTDebug
    if($mc -eq $NULL){New-FASTSearchMetadataCategory -Name FASTDebug -Propset $propertySet }
    $cp = Get-FASTSearchMetadataCrawledProperty -Name cpproperty1 
    if($cp -eq $NULL){New-FASTSearchMetadataCrawledProperty -Name cpproperty1 -Propset $propertySet -VariantType 31}
    $mp = Get-FASTSearchMetadataManagedProperty -Name mpproperty1 
    if($mp -eq $NULL)
    {
      New-FASTSearchMetadataManagedProperty -Name mpproperty1 -Type 1
      $mp = Get-FASTSearchMetadataManagedProperty -Name mpproperty1
      $cp = Get-FASTSearchMetadataCrawledProperty -name $propertyName
      New-FASTSearchMetadataCrawledPropertyMapping -ManagedProperty $mp -CrawledProperty $cp
    }
    

    $pipelineextensibilityfile = "$fastdir\etc\pipelineextensibility.xml"
    
    copy-item ".\pipelineextensibility.xml" $pipelineextensibilityfile
    copy-item "viewcps.bat" "$fastdir\bin\viewcps.bat"
    copy-item $thispsfile $psfile -force
    psctrl reset 
    #TODO: uncheck core results web part "Use Location Visualization" checkbox
    
    #TODO: update the core results web part XSL Editor section automatically and insert the following:
    #            <xsl:value-of disable-output-escaping="yes" select="mpproperty1"/>
    # after this section
    #<xsl:call-template name="DisplaySize">
    #                <xsl:with-param name="size" select="size" />
    #            </xsl:call-template>
    # update the core results web part Fetched Properties section to include <Column Name="mpproperty1"/>
                
}

if($inputfile.length -gt 0 -and $outputfile.length -gt 0) 
{
    mainwork -inputfile $inputfile -outputfile $outputfile
}

if($getFASTcrawledproperties)
{
    get-FASTCrawledProperties
}

if($deploy)
{
    install-debugPipelineExtensibility
}

