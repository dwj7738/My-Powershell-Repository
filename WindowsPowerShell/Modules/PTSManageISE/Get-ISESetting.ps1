<#
.SYNOPSIS
reads one or more settings for the ISE editor
.PARAMETER Name
Name of setting to read. You can use wildcards.
If you do not supply a name, all settings are retrieved.
If you do not use wildcards, only the value will be returned.
If you do use wildcards, the setting name will also be returned.
.EXAMPLE
Get-ISESetting MRUCount
Reads the maximum number of files in your MRU list
.EXAMPLE
Get-ISESetting
returns all settings
.EXAMPLE
Get-ISESetting *wind*
returns all settings with "wind" in their name
#>
Function Get-ISESetting
{
  param
  (
    $Name = '*'
  )

  $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
  $filename = 'user.config'
  $path = Join-Path -Path $folder -ChildPath $filename

  [xml]$xml = Get-Content -Path $path -Raw

  # wildcards used?
  $wildCard = $Name -match '\*'

  # find all settings available with their correct casing:
  $settings = $xml.SelectNodes('//setting') | Where-Object serializeAs -EQ String | Select-Object -ExpandProperty Name
  # translate the user-submitted setting into the correct casing:
  $CorrectSettingName = @($settings -like $Name)

  # if no setting is found, try with wildcards
  if ($CorrectSettingName.Count -eq 0)
  {
    $CorrectSettingName = @($settings -like "*$Name*")
    $wildCard = $true
  }

  if ($CorrectSettingName.Count -gt 1 -or $wildCard)
  {
    $CorrectSettingName |
    ForEach-Object {
      $xml.SelectNodes(('//setting[@name="{0}"]' -f $_)) |
      Select-Object -Property Name, Value
    }
  }
  elseif ($CorrectSettingName.Count -eq 1)
  {
    $xml.SelectNodes(('//setting[@name="{0}"]' -f $CorrectSettingname[0])) |
    Select-Object -ExpandProperty Value
  }
  else
  {
    Write-Warning "The setting '$SettingName' does not exist. Try one of these valid settings:"
    Write-Warning ($settings -join ', ')
  }
}
