Function NextFreeDrive{For($x=67;$x -le 90;$x++){$driveletter=[char]$x+":";
If(!(Test-Path $driveletter)){$driveletter;break}}}