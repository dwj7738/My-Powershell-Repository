Set-PSDebug 
$watcher = New-Object System.IO.FileSystemWatcher -Property @{Path = 'D:\PowerShell\temp';
                                                              Filter = '*.txt';
                                                              NotifyFilter = [System.IO.NotifyFilters]'FileName,LastWrite'}

$CreatedAction = 
{
  $ParentPath = Split-Path -Path $event.sourceEventArgs.FullPath
  $NewDestPath = Join-Path -Path $ParentPath -ChildPath $(($event.sourceEventArgs.Name).Split('.')[0])
  New-Item -Path $NewDestPath -Type Directory
  Start-Sleep -Seconds 2
  Move-Item -Path $($event.sourceEventArgs.FullPath) -Destination $NewDestPath
}

$DeleteAction = 
{
  "File Deleted: $($event.sourceEventArgs.FullPath)" | Out-File -FilePath D:\PowerShell\DeleteActionLog.txt -Append 
}
    
Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action $CreatedAction
Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier FileDeleted -Action $DeleteAction
