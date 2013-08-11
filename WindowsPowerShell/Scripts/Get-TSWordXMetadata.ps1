function Get-TSWordXMetadata {
  <#
    
    .SYNOPSIS
    Displays Metadata Information from a WordX file.

    .DESCRIPTION
    The Get-TSWordXMetadata CmdLet displays Metadata from a WordX file using the Word.Application Com Object.

    .EXAMPLE
    dir C:\foo -Filter *.docx | Get-TSWordXMetadata

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TreuSec
  #>
  param(
    [parameter(Mandatory = $true,
      ValueFromPipeLine = $true,
      ValueFromPipeLineByPropertyName = $true)]
    [Alias("Fullname")]
    [string]$Path
  )
  Process {
    $referenceObject = Get-Process
    $Word = New-Object -comobject Word.Application
    $Word.Visible = $False
    $OpenDoc = $Word.Documents.Open($path)
    $docX = [xml]$OpenDoc.WordOpenXML
    $coreXML = $docX.package.part | Where { $_.name -eq "/docProps/core.xml" }
    $properties = $coreXML.xmlData.coreProperties

    New-Object PSObject -Property @{
      Subject = $(if($properties.subject) { $properties.subject } else { $null });
      Creator = $(if($properties.creator) { $properties.creator } else { $null });
      LastModifiedBy = $(if($properties.lastModifiedBy) { $properties.lastModifiedBy } else { $null });
      Revision = $(if($properties.revision) { $properties.revision } else { $null });
      Created = [datetime]$properties.created.'#text';
      Modified = [datetime]$properties.modified.'#text';
      Category = $(if($properties.category) { $properties.category } else { $null });
      ContentStatus = $(if($properties.contentStatus) { $properties.contentStatus } else { $null })
    }
    $differenceObject = Get-Process
    $compare = Compare-Object -Property ID -ReferenceObject $referenceObject -DifferenceObject $differenceObject
  
    $compare | Where-Object { $_.SideIndicator -eq "=>" } | 
     ForEach-Object {
       $id = $_.ID
       if(Get-Process | Where-Object { $_.ID -eq $id -AND $_.ProcessName -eq "WINWORD" }) {
         Stop-Process -Id $id -Force
       }
     }
  }
}