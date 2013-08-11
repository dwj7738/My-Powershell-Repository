## =====================================================================?
## Title???????: Exchange-Status
## Description : Check the All the required services in the Exchange 2007 Server
## Author??????: Krishna
## Date????????: 10/11/2009?

## ===================================================================== ?
?
?
$ExchServer = Get-ExchangeServer

foreach ($Server in $ExchServer)

{

	echo $Server.name (Test-ServiceHealth $Server)

}