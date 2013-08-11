## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)

Set-StrictMode -Version Latest

Push-Location
Set-Location HKCU:\Console
New-Item '.\%SystemRoot%_system32_WindowsPowerShell_v1.0_powershell.exe'
Set-Location '.\%SystemRoot%_system32_WindowsPowerShell_v1.0_powershell.exe'

New-ItemProperty . ColorTable00 -type DWORD -value 0x00562401
New-ItemProperty . ColorTable07 -type DWORD -value 0x00f0edee
New-ItemProperty . FaceName -type STRING -value "Lucida Console"
New-ItemProperty . FontFamily -type DWORD -value 0x00000036
New-ItemProperty . FontSize -type DWORD -value 0x000c0000
New-ItemProperty . FontWeight -type DWORD -value 0x00000190
New-ItemProperty . HistoryNoDup -type DWORD -value 0x00000000
New-ItemProperty . QuickEdit -type DWORD -value 0x00000001
New-ItemProperty . ScreenBufferSize -type DWORD -value 0x0bb80078
New-ItemProperty . WindowSize -type DWORD -value 0x00320078
Pop-Location
