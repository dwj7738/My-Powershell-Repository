function Get-Inventory {
 PROCESS {
    $computer =$_
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


write-output $obj

    }
}



Get-Content C:\computers.txt | Get-Inventory | write-output



