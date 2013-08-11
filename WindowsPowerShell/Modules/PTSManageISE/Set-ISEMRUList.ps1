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
