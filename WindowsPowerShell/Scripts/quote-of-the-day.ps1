$w = New-WebServiceProxy -Uri 'http://ryanrusson.com/ws/WS.asmx?WSDL'
$w.ChimpOmatic().Tables[0] | Select-Object -ExpandProperty Quote
