#######################################################################################################################                        
# Description:   Download MMS 2013 Channel 9 videos
# PowerShell version: 3                   
# Author(s):     Stefan Stranger (Microsoft)
#                Jamie Moyer (Microsoft          
# Example usage: Run Get-MMS2013Channel9Videos.ps1 -path c:\temp -verbose
#                Select using the Out-Gridview the videos you want to download and they are stored in your myvideos folder.
#                You can multiple select videos, holding the ctrl key.
# Disclamer:     This program source code is provided "AS IS" without warranty representation or condition of any kind
#                either express or implied, including but not limited to conditions or other terms of merchantability and/or
#                fitness for a particular purpose. The user assumes the entire risk as to the accuracy and the use of this
#                program code.
# Date:          04-13-2012                        
# Name:          Get-MMS2013Channel9Videos.ps1            
# Version:       v1.001 - 04-14-2012 - Stefan Stranger - initial release
# Version:       v1.005 - 04-29-2013 - Jamie Moyer, Stefan Stranger - added more robustness and HTML Report
########################################################################################################################
#requires -version 3.0

[CmdletBinding()]
Param
(
        # Path where to store video's locally
        [Parameter(Mandatory=$false,
                   Position=0)]
        
        $Path=[environment]::getfolderpath("myvideos") +"\TechEd2013-Europe", [Parameter(Mandatory=$false,Position=1)]
        $rssfeed="http://channel9.msdn.com/Events/TechEd/Europe/2013/RSS/mp4high"
    )

function Get-NewFileName($name)
{
    Write-Verbose "Calling Get-NewFileName Function"
    $r=$Path+"\"+(($name -replace "[^\w\s\-]*") -replace "\s+") + ".mp4";$r
}

Write-Verbose "Remove last slash if added using the downloaddirectory Parameter"
if ($path.EndsWith("\")){$path = $path.Substring(0,$path.Length-1)}
write-verbose "Path is: $path"

Write-Verbose "Checking if Download directory $Path exists"
if(!(test-path $Path -PathType Container))
{
    Write-Verbose "Creating $Path"
    New-Item -ItemType Directory $Path | Out-Null
}

Write-Verbose "Downloading RSS Feed Items from $rssfeed"
$feeditems = Invoke-RestMethod $rssfeed
[array]$feeditemsWithDetails = $feeditems | 
    select Title, Summary, Duration, Enclosure,creator | 
        Add-Member -MemberType ScriptProperty -Name AlreadyDownloaded -Value {(test-path("$Path\$($this.enclosure.url.split('/')[6])"))} -PassThru -Force |
        Add-Member -MemberType ScriptProperty -Name Destination -Value {("$Path\$($this.enclosure.url.split('/')[6])")} -PassThru -Force |
        Add-Member -MemberType ScriptProperty -Name Source -Value {$this.enclosure.url} -PassThru -Force |
            select AlreadyDownloaded,Title, Summary, Duration, Enclosure,Source,Destination,creator | sort Title

Write-Verbose "Add all already downloaded items back to the list"
$duplicateVideoNames = $feeditemsWithDetails |sort name| group destination | where-object {$_.Name -ne "" -and $_.Count -gt 1} | 
    ForEach-Object {$_.Group}

Write-Verbose "Remove the posts with duplicate file names from the feeditemsSelected array"
$feeditemsSelected = @($feeditemsSelected | Where-Object {$duplicateVideoNames -notcontains $_})

Write-Verbose "Change video names to filenames, check to see if they are downloaded already and added them back to the array with updated details"
$duplicateVideoNames | foreach-object {
                                        $newDestination = Get-NewFileName $_.Title
                                        $_.Destination = $newDestination
                                        $_.AlreadyDownloaded = (Test-Path $newDestination)
                                        $feeditemsWithDetails += $_
                                      }

Write-Verbose "Open Out-GridView to select vidoes to download"
[array]$feeditemsSelected = $feeditemsWithDetails| Out-GridView -PassThru | 
    select AlreadyDownloaded,Title, Summary, Duration, Enclosure,Source,Destination

Write-Verbose "Downloading videos"
$feeditemsSelected |Where-Object{!(Test-Path $_.Destination)} | select Source,Destination | Start-BitsTransfer -Priority Foreground | Out-Null

Write-Verbose "Add all already downloaded items back to the list"
$feeditemsWithDetails | where-object {$_.AlreadyDownloaded} | 
                            foreach-object {
                                                if(-not [bool]($feeditemsSelected | Select-String $_.Title -Quiet))
                                                {
                                                    $feeditemsSelected += $_
                                                }
                                           }

Write-Verbose "Create HTML Report"
$feeditemsSelected | sort Name | Out-Null
$html = $feeditemsSelected |?{Test-Path "$($_.Destination)"} | % {@"
     <H4><a href="$($_.Destination)">$($_.Title)</a></H4> 
     <H5>Speaker(s): $($_.creator)</H5>
     <H5>$($_.Summary)</H5>
"@}

Write-Verbose "Open HTML Report"
ConvertTo-Html -Head "<h1>My Downloaded Teched 2013 Europe Videos - $($feeditemsSelected.Count) Downloaded</h1>" -Body $html | 
    Out-File $Path\MyTeched2013EuropeContent.html
    start "$Path\MyTeched2013EuropeContent.html"