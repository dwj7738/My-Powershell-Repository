function Get-MyShares
{
 param([string]$Server)
 $Shares = Get-WmiObject -Class Win32_Share -ComputerName $Server
 $output = @()
 ForEach ($Share in $Shares)
 {
  $fullpath = “\\{0}\{1}” -f $server, $share.name
  Add-Member -MemberType NoteProperty -InputObject $Share -Name FullPath -Value $fullpath
  $output += $Share
 }
 Return $output
}