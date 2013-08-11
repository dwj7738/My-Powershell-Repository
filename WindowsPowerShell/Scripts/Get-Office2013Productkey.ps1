function Get-SerialNumber {
  $regVal = Get-ItemProperty $regDir.PSPath
  $arrVal = $regVal.DigitalProductId
  $arrBin = $arrVal[52..66]
  $arrChr = "B", "C", "D", "F", "G", "H", "J", "K", "M", "P", "Q", "R", `
            "T", "V", "W", "X", "Y", "2", "3", "4", "6", "7", "8", "9"

  for ($i = 24; $i -ge 0; $i--) {
    $k = 0;
    for ($j = 14; $j -ge 0; $j--) {
      $k = $k * 256 -bxor $arrBin[$j]
      $arrBin[$j] = [math]::truncate($k / 24)
      $k = $k % 24
    }
    $strKey = $arrChr[$k] + $strKey

    if (($i % 5 -eq 0) -and ($i -ne 0)) {
      $strKey = "-" + $strKey
    }
  }
  $strKey
}

#Windows serial key
$regDir = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$key_1 = Get-SerialNumber

#MS Office 2007 serial key
$regDir = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Office\15.0\Registration
$key_2 = Get-SerialNumber

Write-Output "OS       : $key_1"
Write-Output "MS Office: $key_2"