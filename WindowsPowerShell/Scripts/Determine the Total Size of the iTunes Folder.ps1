# ------------------------------------------------------------------
# Title: Determine the Total Size of the iTunes Folder
# Author: The Scripting Community
# Description: Reports the total size (in megabytes) of the C:\Program Files\iTunes folder and its subfolders.
# Date Published: 10-Aug-2009 12:48:53 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/fdb88b63-8fe9-4961-827d-72be1f777f4f
# Rating: 4.5 rated by 2
# ------------------------------------------------------------------

$TotalFSZ=0
 $foltree=get-childitem "C:\Program Files\iTunes" #-recurse
 foreach ($folt in $foltree)    {
    if($folt.mode -match "d")    {
        $fsz=((get-childItem $folt.fullname -recurse | Measure-object length -sum).sum)/1MB 
        $FSize="{0:N2}" -f $fsz
        Write-host $folt.name $fsize  MB
        $TotalFSZ=$TotalFSZ+$fsize
         }
    }
    $filesize=(($foltree | measure-object length -sum).sum)/1MB
    $fsizeMB="{0:N2}" -f $filesize
    Write-host Total Size of Folder is ($TotalFSZ+$fsizeMB)  MB
