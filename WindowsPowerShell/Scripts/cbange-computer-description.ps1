$computer = "WINXP-SYSPREP"
$computerip = "192.168.0.102"
# Registry variables for 'Computer description',
$Hive ="LocalMachine"
$Reg = "SYSTEM\ControlSet001\services\LanmanServer\Parameters\"
$Value = "srvcomment"
$Desc ="David's Windows XP Computer"
# Action part of script
Set-RegString -ComputerName $computer -Hive $Hive -Key $Reg -Value $Value -Data $Desc