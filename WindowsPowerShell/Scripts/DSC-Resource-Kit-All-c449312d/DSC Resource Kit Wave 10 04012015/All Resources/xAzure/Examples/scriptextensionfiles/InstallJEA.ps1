Invoke-WebRequest -Uri 'http://nuget.org/nuget.exe' -OutFile "$env:TEMP\NuGet.exe"
&"$env:TEMP\NuGet.exe" install xJea -NoCache -Source http://msconfiggallery.cloudapp.net/api/v2/ -ExcludeVersion -PackageSaveMode "nuspec" -OutputDirectory "$env:ProgramFiles\WindowsPowerShell\Modules"

&'winrm' quickconfig -quiet

Invoke-WebRequest -Uri 'http://download.microsoft.com/download/5/5/2/55277C4B-75D1-40FB-B99C-4EAFA249F645/WindowsBlue-KB2894868-x64.msu' -OutFile "$env:TEMP\WindowsBlue-KB2894868-x64.msu"
&"$env:TEMP\WindowsBlue-KB2894868-x64.msu" /quiet