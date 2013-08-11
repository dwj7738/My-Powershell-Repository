[CmdletBinding()]
param()
$data = import-csv c:\data.csv
Write-Debug "Imported CSV data"

$totalqty = 0
$totalsold = 0
$totalbought = 0
foreach ($line in $data) {
    if ($line.transaction -eq 'buy') {

        Write-Debug "ENDED BUY transaction (we sold)"
        $totalqty -= $line.qty
        $totalsold = $line.total

    } else {

        $totalqty += $line.qty
        $totalbought = $line.total
        Write-Debug "ENDED SELL transaction (we bought)"

    }
}
