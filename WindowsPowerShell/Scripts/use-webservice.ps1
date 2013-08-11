$URI = "http://www.holidaywebservice.com/HolidayService_v2/HolidayService2.asmx"
$proxy = New-WebServiceProxy -Uri $URI -Class holiday -Namespace webservice
#$proxy.GetCountriesAvailable()
#$proxy.GetHolidaysAvailable("Canada")
#$proxy.GetHolidaysAvailable("Canada") | sort code
$FD = $proxy.GetHolidayDate("CANADA","FAMILY-DAY",2013)

$ts = New-TimeSpan -Start (get-date) -End ($proxy.GetHolidayDate("CANADA","FAMILY-DAY",2013))
write-output($FD.Date)
write-output ([string]$ts.Days + " Days Until Family Day")

