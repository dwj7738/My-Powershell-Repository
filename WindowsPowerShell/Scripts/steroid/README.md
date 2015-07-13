# steroid

### BinUtils
##### `Get-DumpBin`
*Gets dump of a binary file.*

### CLR
##### `Get-AssemblyEnum`
*Shows all assemblies or finds specified assembly in GAC.*
##### `Get-GACPath`
*Finds global assembly cache path.*
##### `Show-KnownFrameworks`
*Gets known .NET platforms for the current management framework.*

### Misc
##### `Convert-Hex2Dec (alias: hex2dec)`
*Converts hex to decimal and vice versa.*
##### `Get-Calendar`
*Prints calendar for the given month.*
##### `Get-Strings (alias:strings)`
*Searches strings in a file.*

### Winternals
##### `Get-ClockRes (alias:clockres)`
*ntdll.dll!NtQueryTimerResolution wrapper. Gets system clock resolution.*
##### `Get-CPUInfo (alias:cpuinfo)`
*Displays detailed information about CPU (WinDbg !cpuinfo).*
##### `Get-DiskDrive`
*Gets basic info of drives (alternative for Win32_DiskDrive).*
##### `Get-GlobalMemoryStatus`
*kernel32.dll!GlobalMemoryStatusEx wrapper (reflection).*
##### `Get-LastLogonTime (alias:loggedon)`
*Gets the time of the last logon of the current user.*
##### `Get-LoadedDrivers`
*Gets list of loaded drivers.*
##### `Get-LogonSessions`
*Describes the logon session or sessions associated with a user (instead Win32_LogonSession class).*
##### `Get-ProcessMemory (alias:vprot)`
*Retrieves virtual memory information of the given process (WinDbg !vprot).*
##### `Get-ProcessOwner`
*Retrieves user name and parent ID of the given process(es).*
##### `Get-RegistryHives`
*Shows loaded registry hives.*
##### `Get-Streams (alias:streams)`
*Enumerates alternate NTFS data streams.*
##### `Get-SystemFileCache`
*Shows system file cache status.*
##### `Get-Uptime (alias:uptime)`
*Gets system uptime.*
##### `Set-Privilege`
*Adjusts privilege for the given process (reflection).*
##### `Set-ProcessWorkingSetSize`
*kernel32.dll!SetProcessWorkingSetSize wrapper. Minimizes the working set of the specified process.*
##### `Write-ProcessDump (alias:procdump)`
*Creates mini dump of the given process.*
