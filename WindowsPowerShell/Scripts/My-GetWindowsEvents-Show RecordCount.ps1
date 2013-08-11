Get-WinEvent -ListLog * -ErrorAction 'SilentlyContinue'  | 
Where-Object{$_.IsEnabled -and $_.RecordCount -gt 0} | 
Sort-Object -Property RecordCount -Descending | 
Format-Table Logname, RecordCount
