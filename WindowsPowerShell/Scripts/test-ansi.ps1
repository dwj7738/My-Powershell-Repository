$utf8 = get-content "D:\Documents\3- utf8.txt"
$utf8 | out-file -Encoding utf8 -FilePath c:\temp\1.txt
$utf8 | Out-File -Encoding ascii -FilePath 'C:\temp\2.txt'
$utf8 | Out-file -Encoding unicode -FilePath 'C:\temp\3.txt'
$utf8 | out-file -Encoding unicode
get-content c:\temp\1.txt
get-content 'C:\temp\2.txt'
get-content 'C:\temp\3.txt'
Remove-Item c:\temp\1.txt
Remove-Item C:\temp\2.txt
Remove-Item C:\temp\3.txt
