<#
.SYNOPSIS
sets a settings for the ISE editor
.PARAMETER Name
Name of setting to change.
.PARAMETER Value
New value for setting. There is no validation. You are responsible for submitting valid values.
.EXAMPLE
Set-ISESetting MRUCount 12
Sets the maximum number of files in your MRU list to 12
#>
Function Set-ISESetting
{
  param
  (
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Name,

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Value
  )

  Begin
  {
    $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
    $filename = 'user.config'
    $path = Join-Path -Path $folder -ChildPath $filename

    [xml]$xml = Get-Content -Path $path -Raw

    # find all settings available with their correct casing:
    $settings = $xml.SelectNodes('//setting') | Where-Object serializeAs -EQ String | Select-Object -ExpandProperty Name
  }

  Process
  {
    # translate the user-submitted setting into the correct casing:
    $CorrectSettingName = $settings -like $Name

    if ($CorrectSettingName)
    {
      $xml.SelectNodes(('//setting[@name="{0}"]' -f $CorrectSettingName))[0].Value = [String]$Value
    }
    else
    {
      Write-Warning "The setting '$SettingName' does not exist. Try one of these valid settings:"
      Write-Warning ($settings -join ', ')
    }
  }

  End
  {
    $xml.Save($Path)
  }
}
