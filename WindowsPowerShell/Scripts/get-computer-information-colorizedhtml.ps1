$computer = Env:\COMPUTERNAME
$outpath = "c:\scripts\"
$outfile = $outpath + $computer + ".html"
$a = "<style>"
$a = $a + "BODY{background-color:darkgrey;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:White}"
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:Yellow}"
$a = $a + "</style>"

$os = Get-WmiObject Win32_OperatingSystem -ComputerName $computer
$bios = Get-WmiObject Win32_BIOS -ComputerName $computer
$os_build = $os.buildnumber
$os_spver = $os.servicepackmajorversion
$bios_ser = $bios.serialnumber
$obj = new-object psobject
$obj | add-member -MemberType  NoteProperty -Name ComputerName -Value $computer
$obj | add-member -MemberType  NoteProperty -Name BiosSerial -Value $bios_ser
$obj | add-member -MemberType  NoteProperty -Name BuildNumber -Value $os_build
$obj | add-member -MemberType  NoteProperty -Name SPVersion -Value $os_spver
$obj |ConvertTo-Html -Head $a -Body "<center><H2>Computer Information</H2>" | 
Out-File -FilePath $outfile
Get-Service | Select-Object Status, Name, DisplayName | 
ConvertTo-HTML -head $a -body "<H2>Service Information</H2>" | 
Out-File -FilePath $outfile -Append
Get-Process | Select-Object ProcessName, CPU, ID |
ConvertTo-Html -Head $a -Body "<H2>Process Information</H2>" | 
Out-File -filepath $outfile -Append
"</center>" | out-file -filepath $outfile -append
invoke-expression $outfile

