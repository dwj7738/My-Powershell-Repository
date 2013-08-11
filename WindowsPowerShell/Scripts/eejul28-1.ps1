    param (
        [Parameter(Mandatory=$true)] 
        $NetLocName
        )
    
    $NetLocName

    #cls
    # Constants
    $const_NETHOOD = 0x13
    $oApp = new-Object -com Shell.Application
    $oShell = new-Object -com Wscript.Shell
    $NetHood = ($oApp.Namespace($const_NETHOOD)).Self.Path
    $NetLocLocalPath = "$NetHood\$NetLocName"
    $NetLocTargetPath = $NetLocName + [String]::Join("", $Env:ComputerName[-2..-1]) + "\"
    $NetLocTargetPath
                                            

if ( !(test-Path $NetLocTargetPath) ) # -pathType container) )
{
      write-Host "Problem with inputted target path:  $NetLocTargetPath"
      write-Host "Exiting..."
      exit
}


if ( !(test-Path $NetLocLocalPath -pathType container) )
{
      new-Item $NetLocLocalPath -type directory -force
      attrib "$NetLocLocalPath" +R
}

if ( !(test-Path "$NetLocLocalPath\Desktop.ini" -pathType leaf) )
{
      $oFile = new-Item "$NetLocLocalPath\Desktop.ini" -type file -force
      add-Content $oFile "[.ShellClassInfo]"
      add-Content $oFile "CLSID2={0AFACED1-E828-11D1-9187-B532F1E9575D}"
      add-Content $oFile "Flags=2"
      attrib "$NetLocLocalPath\Desktop.ini" +H +S -A
}


if ( (test-Path "$NetLocLocalPath\target.lnk" -pathType leaf) )
{
      $oLnk = $oShell.CreateShortcut("$NetLocLocalPath\target.lnk")
      $OldLnk = $oLnk.TargetPath

      if ($OldLnk -ne $NetLocTargetPath)
      {
            $oLnk.TargetPath = $NetLocTargetPath
            $oLnk.Save()
      }
}
else {
      $oLnk = $oShell.CreateShortcut("$NetLocLocalPath\target.lnk")

      $oLnk.TargetPath = $NetLocTargetPath
      $oLnk.Save()
    }



