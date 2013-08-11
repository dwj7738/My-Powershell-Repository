
$path = Read-Host("Path to Search")
$searchcompany = Read-host("Company to Search For")
$files = get-childitem($path)
foreach($filename in $files) {
$shell = New-Object -COMObject Shell.Application
$folder = Split-Path $filename.FullName
$file = $filename.Name
$shellfolder = $shell.Namespace($folder)
$shellfile = $shellfolder.ParseName($file)
$company = $shellfolder.GetDetailsOf($shellfile, 33)
if ($company -eq $searchcompany){
    $out = $file + "     " + $company
    $out
       Remove-Item $filename.FullName -Confirm
    }
}