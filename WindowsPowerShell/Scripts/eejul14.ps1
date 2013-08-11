Measure-Command {
Copy-Item -Path c:\temp\data1s.xlsx -Destination C:\temp\data1.xlsx -Force
set-psdebug -trace 2 -step

$strPath="c:\temp\data1.xlsx"
$objExcel = New-Object -ComObject Excel.Application
$objExcel.Visible=$true
$WorkBook = $objExcel.Workbooks.Open($strPath)
$worksheet = $workbook.sheets.item("ED")
$worksheet2 = $workbook.sheets.item("COMPANY")

2..15 | %{
	$rowNum = $_
	$name = $worksheet.cells.item($rowNum,2).Value()
	$comp = $worksheet2.cells.item($rowNum,2).Value()

    $splitted = $name.Split(",")
    $maximum = $splitted.Count
    $email = $splitted[0]
        for ($counter = 1; $counter -le $maximum; $counter++) {
             if ($splitted[$counter] -ne $null){
                $email = $email + "." + $splitted[$counter]
                $email =  $email -replace " ",""
                }
            }
$domain = $objexcel.workSheetFunction.VLOOKUP("C2,COMPANY!A:B,2,FALSE")
        $email = $email + $code +"@" + $domain
        $email = $email.ToLower()
    $worksheet.cells.item($rowNum,4) = "{0}" -f $email
    $email = ""
    $code = ""
}
$WorkBook.Save()
$objExcel.Quit()
}
start $strPath
