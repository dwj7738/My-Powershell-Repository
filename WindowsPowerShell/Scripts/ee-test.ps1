$D = "-" + (get-date).year + "-" + (get-date).month + "-" + (get-date).day
cd "c:\scripts\"
$F = "c:\scripts\logs\server5" + $D + ".log"
xcopy "H:\Documents\Audible\non-mp3 Downloads\Robin Cook\Mutation\*.*" H:\server5  /E /C /G /H /R /O /Y >$F
exit