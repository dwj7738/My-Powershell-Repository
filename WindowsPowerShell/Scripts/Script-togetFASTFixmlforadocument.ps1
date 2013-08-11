<#
.SYNOPSIS
	Gets the FAST Fixml encoding for a document
.DESCRIPTION
	This script does the following:
	Find the FIXML file containing the target document
	Expand (unzip) the FIXML file
	Pull out the <document> fragment and save that to a file by itself
	(Optionally) Calls Get-FASTSearchSecurityDecodedSid for all acls
.PARAMETER InternalId
	FAST internal id of the document you want to retrieve
.PARAMETER OutputFile
	Output file to write to.  If not specified a file will be created in $FASTSEARCH\var and named INTERNALID.xml.  If specified, it should be a full path name.
.PARAMETER ConvertAcls
	If specified, the associated ACLS will be pulled and decoded
.EXAMPLE 
Get-FASTFixml.ps1 8ae5e43c3639bb9b4fd1fec8f27a53d6_sp -OutputFile $env:TEMP\foo.xml
Expanding D:\FASTSEARCH\data\data_fixml\Set_000009\Elem_c7.xml.gz into D:\FASTSEARCH\Var\Fixml.xml
Writing document to C:\Users\esadmin\AppData\Local\Temp\6\foo.xml
.NOTES
	File Name : Get-FASTFixml.ps1
	Author    : Brent Groom <brent.groom@microsoft.com>, Matthew King <matthew.king@microsoft.com>

#>

param(
	[Parameter(Mandatory=$True)]
	[string]$InternalId,
	[string]$OutputFile = $null,
	[switch]$ConvertAcls = $false
)

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

#Given a ssic, get the internalid from qrserver, get the fixml, get the acl info from fixml, decode the sid list, perform a query as a specific user, get the sid list of a user
# given the internalid: get the fixml
$FASTSEARCH = [environment]::GetEnvironmentVariable("FASTSEARCH","Machine").toUpper()
if (-not $FASTSEARCH -or (-not (Test-Path $FASTSEARCH))) {
	Write-Error "FAST not found $FASTSEARCH"
	return
}
$selp1 = "." + $InternalId
$selp2 = Join-Path $FASTSEARCH "data\data_index\[0-9]\*[0-9]\index_data\urlmap_sorted.txt"
$fixmlfile = Select-string $selp1 $selp2

#$fixmlfile
#get the fixml gz file from the string: 
#C:\FASTSEARCH\data\data_index\0\index_1273910473294360000\index_data\urlmap_sorted.txt:22:.6938082d1772acf381d76dd8508a9b56_sp,Set_000106\Elem_63.xml.gz 1
$strval = [String]$fixmlfile
$splitstrval = $strval.split(",")
$rightside = $splitstrval[1]
$splitrightside = $rightside.split(" ")
$leftside = $splitrightside[0]

$inputfile = Join-Path $FASTSEARCH "data\data_fixml\$leftside"
$fixmlfile = Join-Path $FASTSEARCH "Var\Fixml.xml"

Write-Host "Expanding $inputfile into $fixmlfile"

@"
import gzip
import sys
i = gzip.open(sys.argv[1])
o = open(sys.argv[2],"w")
o.writelines(i.readlines())
i.close()
o.close()
"@ | Out-File -encoding ascii "$FASTSEARCH\bin\unpackfixml.py"
$fixmlpy = Join-Path $FASTSEARCH "bin\unpackfixml.py"

if (Test-Path $fixmlfile) { rm $fixmlfile }

$cobra = Join-Path $FASTSEARCH "bin\cobra"
& $cobra $fixmlpy $inputfile $fixmlfile

if (-not (Test-Path $fixmlfile)) {
	Write-Error "Cannot find output file '$fixmlfile'"
	return
}

[xml]$xmldata = Get-Content $fixmlfile
$node = $xmldata.SelectNodes("/fixmlDocumentCollection/document/summary/sField[@name='internalid'][.='$InternalId']")
if (-not $node) {
	Write-Error "Failed to find document in fixml"
	return 1
}
$node = $node.Item(0)
$doc = $node.ParentNode.ParentNode

if (-not $OutputFile) {
	$OutputFile = Join-Path $FASTSEARCH "var\$InternalId.xml"
}
Write-Host "Writing document to $OutputFile"
$writerSettings = New-Object System.Xml.XmlWriterSettings
$writerSettings.Indent = $true
$writer = [System.Xml.XmlWriter]::Create($OutputFile, $writerSettings)
$doc.WriteTo($writer)
$writer.Flush()
$writer.Close()

if ($ConvertAcls) {
	$docacl = $doc.SelectNodes("//context[@name='bcondocacl']")
	if (-not $docacl) { 
		Write-Error "Failed to find the document in the fixml file"
		return
	}
	$aclstr = $docacl.get_ItemOf(0).get_InnerText()
	#$aclstr 
	# split on ' ' and iterate the list
	$acls = $aclstr.split(" ")
	#$acls
	"List of permit Acls on the doc"
	foreach($acl in $acls)
	{
	  if($acl.StartsWith('win'))
	  {
		$encodedsid=$acl.Substring(3)
		#$encodedsid
		Get-FASTSearchSecurityDecodedSid -EncodedSID $encodedsid
	  }
	}

	"List of deny Acls on the doc"
	foreach($acl in $acls)
	{
	  if($acl.StartsWith('9win'))
	  {
		$encodedsid=$acl.Substring(4)
		#$encodedsid
		Get-FASTSearchSecurityDecodedSid -EncodedSID $encodedsid
	  }
	}
}
