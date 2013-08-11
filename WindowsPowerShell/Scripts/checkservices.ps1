# Function to check windows services related to SQL Server
Function f  ([string] $Hostname, [string] $ServiceName )
{
$Services=(get-wmiobject  -ComputerName $Hostname -Filter "Name .like ('*' + $ServiceName + '*')")
foreach ( $service in $Services)
{ 
if($service.state -ne "Running" -or  $service.status -ne "OK" -or $service.started -ne "True" )
{
$message="Host="+$Hostname+" " +$Service.Name +"   "" +$Service.state +" +$Service.status +" " +$Service.Started +" " +$Service.Startname 
write-host $message -BackgroundColor "Red" -ForegroundColor "Black"

}
else
{
$message="Host="+$Hostname+" " +$Service.Name +"   " +$Service.state +" " +$Service.status +"   " +$Service.Started +" " +$Service.Startname
write-host $message -BackgroundColor "Black" -ForegroundColor "Yellow"
}
}
}