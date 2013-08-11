$folder = "$env:userprofile\Downloads"
Get-ChildItem -Path $folder -Recurse -Force -ea 0 |
  Measure-Object -Property Length -Sum |
  ForEach-Object {
    $sum = $_.Sum / 1MB
    "Your Downloads folder wastes {0:#,##0.0} MB storage" -f $sum
}