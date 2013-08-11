function Add-Clock {
$code = {
    $pattern = '\d{2}:\d{2}:\d{2}'
    do {
      $clock = Get-Date -format 'HH:mm:ss' 
      $oldtitle = [system.console]::Title
      if ($oldtitle -match $pattern) {
        $newtitle = $oldtitle -replace $pattern, $clock
      } else {
        $newtitle = "$clock $oldtitle"
      }
      [System.Console]::Title = $newtitle
      Start-Sleep -Seconds 1
    } while ($true)
 }
 $ps = [PowerShell]::Create()
$null = $ps.AddScript($code)
$ps.BeginInvoke()
}
