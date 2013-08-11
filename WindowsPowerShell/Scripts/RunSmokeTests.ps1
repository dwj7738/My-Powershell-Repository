Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

$NumPassedTests = 0
$NumFailedTests = 0
$NumExpectedFailedTests = 0
$ssa = Get-SPEnterpriseSearchServiceApplication


Function testCP([String]$cpname, [switch]$returnanswer, [switch]$notCheck )
{
    $success = $false
    $cp = Get-FASTSearchMetadataCrawledProperty -name $cpname -ea silentlycontinue
    if( $cp ) 
    {
        if($notCheck)
        {
            $success = $false
        }
        else
        {
            $success = $true
        }
    }
    else
    {
        if($notCheck)
        {
            $success = $true
        }
        else
        {
            $success = $false
        }
    }
    if( !$success ) 
    {
        Write-Host ("FAILED - Test: CrawledProperty: " + $cpname ) -ForegroundColor Red
        $script:NumFailedTests++
    }
    else
    {
        Write-Host ("PASSED - Test: CrawledProperty: " + $cpname ) -ForegroundColor Green
        $script:NumPassedTests++
        $success = $true
    }
    
    if( $returnanswer ) { return $success }
}


Function testMP([String]$mpname, [String]$member="skip", [String]$expectedvalue, [switch]$returnanswer, [switch]$notCheck)
{
    $success = $false
    $mp = Get-FASTSearchMetadataManagedProperty -name $mpname -ea silentlycontinue
    if( !$mp ) 
    {
        Write-Host ("FAILED - Test: ManagedProperty: " + $mpname + " - does not exist.") -ForegroundColor Red
        $script:NumFailedTests++
    }
    elseif( !($mp.$member) -and !($member -eq "skip" ) )
    {
        Write-Host ("FAILED - Test: ManagedProperty: " + $mpname + " : " + $member + " - member does not exist.") -ForegroundColor Red
        $script:NumFailedTests++
    }
    elseif( !($mp.$member -eq $expectedvalue) -and !($member -eq "skip") )	
    {
        Write-Host ("FAILED - Test: ManagedProperty: " + $mpname + " : " + $member + " : " + $mp.$member + " != " + $expectedvalue) -ForegroundColor Red
        $script:NumFailedTests++
    }
    else
    {
       if( $member -eq "skip" )
       {
           Write-Host ("PASSED - Test: ManagedProperty: " + $mpname + " - exists.") -ForegroundColor Green  
       }
       else 
       {
           Write-Host ("PASSED - Test: ManagedProperty: " + $mpname + " : " + $member + " = " + $expectedvalue) -ForegroundColor Green  
       }
       $script:NumPassedTests++
       $success = $true
    }
    if( $returnanswer ) { return $success }
}


Function testMPtoCPMapping([String]$mpname, [String]$cpname, [switch]$returnanswer, [switch]$notCheck)
{

    if( (testMP $mpname -returnanswer) -and (testCP $cpname -returnanswer) )
    {
            
        $mp = Get-FASTSearchMetadataManagedProperty -name $mpname -ea silentlycontinue
        $mappings = $mp.GetCrawledPropertyMappings()
        $count = 0
        foreach ($mapping in $mappings)
        {
            $count++
            if( $mapping.name -eq $cpName ) { $success = $true; break}
            else { $found += " " + $count + ") "+ $mapping.name }
        }
    }


    if( $success )
    {
        Write-Host ("PASSED - Test: CrawledProperty: " + $cpname + " -> ManagedProperty: "  + $mpname + " is mapped correctly.") -ForegroundColor Green
        $script:NumPassedTests++
    }
    else
    {
        Write-Host ("FAILED - Test: CrawledProperty: " + $cpname + " -> ManagedProperty: " + $mpname + " is NOT mapped.") -ForegroundColor Red
        write-HOST ("  Found instead crawled properties:" + $found) -ForegroundColor Red
        $script:NumFailedTests++
    }
    if( $returnanswer ) { return $success }
}


Function testURL([String]$testname, [String]$theurl, [String]$expectedtext, [switch]$notCheck)
{

    # sleep loop until co
    $tempdir = $Env:temp  
    $tempfile = "$tempdir\smoketest.htm" 
    $client = (new-object Net.WebClient) 

    $cred = [System.Net.CredentialCache]::DefaultCredentials
    $client.Credentials = $cred

    #$client.Credentials = New-Object System.Net.NetworkCredential("pkmacct", "???","redmond")
    
    While ($client.isBusy) { Start-Sleep -Seconds 1 }             
    
    $client.DownloadFile($theurl,$tempfile) 
    $client.dispose() 
     
    try 
    { 
        $docHtml = [io.file]::ReadAllText($tempfile) 
        #Remove-Item $tempfile 
 
        if ($docHtml.indexOf("$($expectedtext)") -gt 0) 
        { 
            Write-Host ("PASSED - Test: " + $testname) -ForegroundColor Green
            $script:NumPassedTests++
        } 
        else
        {
            Write-Host ("FAILED - Test: " + $testname) -ForegroundColor Red
            $script:NumFailedTests++
            #TODO on error write full details to a log file
        }
    }
    catch
    {
        Write-Error "There was error reading the url:$($theurl)" 
        $_ 
        return 
    }
}



""
"--------------Display Global Variables Properties-------------"
""
$env:hellobrent

""
"--------------Test Crawled Properties-------------"
""

testCP cpe
testCP cpv
testCP cpp
"Should not exist..."
testCP xxa -notCheck

""
"--------------Test Managed Properties-------------"
""
testMP pbjmpe RefinementEnabled $true
testMP pbjmpp RefinementEnabled $true
testMP pbjmpv RefinementEnabled $true

""
"--------------Test Managed Properties to Crawled Property Mappings -------------"
""
testMPtoCPMapping pbjmpp cpp 
testMPtoCPMapping pbjmpe cpe 
testMPtoCPMapping pbjmpv cpv



#$searchcenterquery = "http://intranet.contoso.com/search/Pages/results.aspx"
$searchcenterquery = "http://intranet.contoso.com/search/Pages/results.aspx?k="

<#
""
"--------------Test Synonyms---------------"
""
# note synonyms unlike fast synonyms, only act as an additional trigger for a best bet, does not affect query terms or search results.
testURL "One Way Synonym: picture --> image" ($searchcenterquery + "image") "SharePoint Images"
testURL "Two Way Synonym; group <--> team" ($searchcenterquery + "team") "Team Foundation Server"
"Should not exist..."
testURL "Keyword 'home' should not have a synonym" ($searchcenterquery + "home") "xxyxx"
$NumExpectedFailedTests += 1
#>

""
"--------------Test Page Content---------------"
""
testURL "Refine By: v1" ($searchcenterquery + "pbj") "Refine By: v1"
testURL "Refine By: e1" ($searchcenterquery + "pbj") "Refine By: e1"
testURL "Refine By: p1" ($searchcenterquery + "pbj") "Refine By: p1"
testURL "Search for document: xml1.xml" ($searchcenterquery + "pbj") "xml1.xml"
testURL "Search for document: xml2.xml" ($searchcenterquery + "pbj") "xml2.xml"
#"Should not exist..."
#testURL "Result should not contain 'xxyxx'" ($searchcenterquery + "a") "xxyxx"

#TODO Add two tests to check for refiner values

Write-Host ("") -ForegroundColor Yellow
Write-Host ("") -ForegroundColor Yellow
Write-Host ("-----------------------------------------") -ForegroundColor Yellow
Write-Host ("--------    Smoke Test Summary   --------") -ForegroundColor Yellow
Write-Host ("-----------------------------------------") -ForegroundColor Yellow
Write-Host ("Total tests Executed: $($script:NumPassedTests + $script:NumFailedTests)") -ForegroundColor Yellow
Write-Host ("Total tests Passed: $($script:NumPassedTests)") -ForegroundColor Green
Write-Host ("Total tests Failed: $($script:NumFailedTests)") -ForegroundColor Red
Write-Host ("Total expected Failure: $($script:NumExpectedFailedTests)") -ForegroundColor Red


#
