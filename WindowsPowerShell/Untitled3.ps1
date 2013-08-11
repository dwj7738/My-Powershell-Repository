# (C) 2012 Dr. Tobias Weltner, MVP PowerShell
# www.powertheshell.com
# you can freely use and distribute this code
# we only ask you to keep this comment including copyright and url
# as a sign of respect. 

# more information and documentation found here:
# http://www.powertheshell.com/iseconfig/


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


<#
.SYNOPSIS
adds a new file path to the MRU list or replaces the list with new files 
.PARAMETER Path
Path to add to the list. Can be an array, can be received from the pipeline.
.PARAMETER Append
Adds the path(s) to the existing list
.EXAMPLE
Set-ISEMRUList -Path c:\dummy -Append
Adds a new path to the MRU list, keeping the old paths.
.EXAMPLE
dir $home *.ps1 -recurse -ea 0 | Select-Object -ExpandProperty Fullname | Set-ISEMRUList
replaces existing MRU list with the paths to all powershell script files in your profile
If the list exceeds the number of entries defined in the ISE setting MruCount, the remainder is truncated.
#>
Function Set-ISEMRUList
{
  param
  (
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String[]]
    $Path,

    [Switch]
    $Append
  )

  Begin
  {
    $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
    $filename = 'user.config'
    $configpath = Join-Path -Path $folder -ChildPath $filename

    [xml]$xml = Get-Content -Path $configpath -Raw

    $PathList = @()
  }

  Process
  {
    $Path | ForEach-Object { $PathList += $_ }
  }

  End
  {
    if ($Append)
    {
      $PathList += @($xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.string)
    }

    # is list too long?
    $max = Get-ISESetting -Name MRUCount
    $current = $PathList.Count

    if ($current -gt $max)
    {
      if (!$Append)
      {
        Write-Warning "Your MRU list is too long. It has $current elements but MRUCount is limited to $max elements."
        Write-Warning "Truncating the last $($current - $max) elements."
        Write-Warning 'You can increase the size of your MRU list like this:'
        Write-Warning "Set-ISESetting -Name MRUCount -Value $current"
      }

      $PathList = $PathList[0..$($max-1)]
    }

    $xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.InnerXML = $PathList |
    ForEach-Object { "<string>$_</string>" } |
    Out-String
    $xml.Save($configpath)
  }
}

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