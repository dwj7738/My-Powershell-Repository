
$block = {
  Write-Host ("hello, world: {0}, {1}" -f $env:USERNAME, (hostname))
}
$username = "administrator"
$password = "zardon#1"   
$adjPwd = $password | ConvertTo-SecureString -asPlainText -Force
$testCred = (New-Object System.Management.Automation.PSCredential($username,$adjPwd))    
$serverName = "davidjohnson-w8"
switch ($choice)
{
  "basic"       { Invoke-Command -scriptblock $block }
  "remote"      { Invoke-Command -ScriptBlock $block -computername $serverName }
  "credentialA" { Invoke-Command -ScriptBlock $block -computername $serverName -credential $testCred  }
  "credentialB" { Invoke-Command -ScriptBlock $block -computername $serverName -credential $testCred  -Authentication Credssp}
  "session"     { 
      $testSession = New-PSSession -computername $serverName -credential $testCred -Authentication Credssp
      if ($testSession) { Invoke-Command -ScriptBlock $block -Session $testSession; Remove-PSSession $testSession }
      }
}
