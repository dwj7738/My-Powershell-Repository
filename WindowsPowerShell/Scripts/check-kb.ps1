#range check
function range-check($address)
{
if (($address -lt 0) -OR ($address -gt 255)) {
     write-error("Invalid Address");
     return $false;
     }
else {return $true;}
}
#
function myping($checking){
$r = Test-Connection -ComputerName $checking -Count 1 -Quiet -ErrorAction SilentlyContinue
return $r
}
function check-kb {
[int]$start = 0
[int]$end = 0
[int]$i = 0
$working = "."
$subnet = "192.168.0"
$subnet = read-host("Subnet: 192.168.0")
$start= read-host("IP Starting Address (0-255)")
$end = read-host("IP Ending Address    (0-255)")
if (!(range-check($start) ) ) { return ; }
if (!(range-check($end) ) ) { return ; }
if ([int]$start -gt [int]$end) {
     write-error ("Starting Address must be Less than or Equal to Ending Address")
     return;
     }
else {
#check address reachable $subnet + "." + $adr
$i = $start
do  {
$checking = $subnet + "." + $i
Write-Progress -activity "Checking Computers" -status "Percent Checked: " -percentComplete ($i /  $end * 100)

# ping $checking
# if reachable return 0
# if unreachable return 1
if ((myping $checking) -eq $true) {
  try {
     #  get-hotfix -id KB957095 -computername $checking
     if (!(get-hotfix -ComputerName $checking))
        {
         add-content $checking -path Missing-kb957095.txt
       }
       }
catch [System.UnauthorizedAccessException]{
"Unauthorized " + $checking | ft

       }
catch   {
     add-content $checking -path Missing-kb957095.txt
    }

   }
   $i++
   } while ( $i -le $end)
  
     get-childitem -File ".\Missing-kb957095.txt"
    }
}