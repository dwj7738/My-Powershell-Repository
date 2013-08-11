$strold =  'C:\Temp\data1s.xlsx'
$strpath = 'C:\Temp\data1.xlsx'
copy $strold $strpath

$xls = New-Object -ComObject Excel.Application
$xls.Visible = $true
$wb   = $xls.Workbooks.Open($strPath)

$wb.Sheets.Item('ED').UsedRange.Rows | select -Skip 1 | ? { $_.Cells.Item(1).Value2 } |
  % {
    $actRow = $_.Cells
    $actRow.Item(2).Value2.ToLower() -match "^(?<last>[\w\s-]+),( (?<middle>[\w]+))? (?<first>[\w-]+)( (?<code>[\w()]+))?$" | Out-Null
    $first, $middle, $middle2, $last = $matches["first", "middle", "middle2", "last"]  -replace "[\W]","."
    $code    = $matches["code"]   -replace "[()]"

    if ($middle)  { $middle = "." + $middle }
    if ($code)    { $code = "." + $code }
   
  $actRow.Item(13).Formula = "= ""{0}{1}{2}.{3}{4}@"" & VLOOKUP(C{$actrow}, Company!A:B, 2, false)" -f $first,$middle,$middle2,$last,$code,$_.Row
    $actRow.Item(13).Formula = $_.Cells.Item(13).Value2
}

$wb.Save()
$xls.Quit()
start $strpath                                            