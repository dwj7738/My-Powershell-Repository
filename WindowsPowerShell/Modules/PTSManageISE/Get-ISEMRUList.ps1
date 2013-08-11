<#
.SYNOPSIS
dumps the current path names in the ISE MRU list 
.EXAMPLE
Get-ISEMRUList
dumps the paths to all recently used files in the ISE editor
#>
Function Get-ISEMRUList
{
  $newfile = 'c:\somescript.ps1'

  $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
  $filename = 'user.config'
  $path = Join-Path -Path $folder -ChildPath $filename

  [xml]$xml = Get-Content -Path $path -Raw
  $xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.string
}
