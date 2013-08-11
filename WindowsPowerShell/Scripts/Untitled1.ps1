$watcher = New-Object System.IO.FileSystemWatcher -Property @{Path = 'D:\PowerShell\Temp';
                                                              Filter = '*.txt';
                                                              NotifyFilter = [System.IO.NotifyFilters]'FileName,LastWrite'}d:

$CreatedAction =
{
  
  Write-Output("Starting File check")

  $ParentPath = $event.sourceEventArgs.FullPath
  $filecontents = Get-Content $ParentPath
  $b = $FileContents[$FileContents.Count-1]
    if (!$b.Contains("|RB|"))  {
    Write-debug ("String Not Found")
    }
    else {
    ## found '|RB|"
    write-output("Found")
    #copy line by line removing line with |RB|
    for ($counter = 0; $counter = $a.Count-2; $counter++) {
                $tempFile = [IO.Path]::GetTempFileName()
                $FileContents[$counter] | ]Out-File $tempFile
                write-debug ($fileContents[$counter])
                write-debug ("Temporary file = $tempFile")
                Write-Debug ("Parent Path = $parentpath")
                                }
     Copy-Item $tempFile $parentpathh -Force
     Remove-Item $tempFile
     }
     Start-Sleep -Seconds 2
     Move-Item -Path $($event.sourceEventArgs.FullPath) -Destination $NewDestPath
}            

Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action $CreatedAction
