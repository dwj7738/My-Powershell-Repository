Measure-Command {


Copy-Item -Path C:\temp\data1s.xlsx -Destination C:\temp\data1.xlsx -Force

$strPath="c:\temp\data1.xlsx"
$domainMap = @{}
$objExcel = New-Object -ComObject Excel.Application
$objExcel.Visible=$true
$WorkBook = $objExcel.Workbooks.Open($strPath)
$worksheetCompany = $workbook.sheets.item("COMPANY")
$worksheetED = $workbook.sheets.item("ED")

$rowNum = 2

do{
	$compshort = $worksheetCompany.cells.item($rowNum,1).Value()
	if($compshort -eq $null) {break}
	$domainMap[$compshort] = $worksheetCompany.cells.item($rowNum++,2).Value()
}while($true)

$rowNum = 2

do{
	$compshort = $worksheetED.cells.item($rowNum,3).Value()
	if($compshort -eq $null) {break}
	$domain = $domainMap[$compshort]
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


        $email = $email + $code +"@" + $domain
        $email = $email.ToLower()
    $worksheet.cells.item($rowNum,4) = "{0}" -f $email
    $email = ""
    $code = ""
}
	$worksheetED.cells.item($rowNum++,4) = $domain
}while($true)





$WorkBook.Save()
$objExcel.Quit()
}

start $strPath                                            