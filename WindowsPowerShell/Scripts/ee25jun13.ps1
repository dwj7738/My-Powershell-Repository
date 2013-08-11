<#

   <connectionStrings>
      <add name="ConStringPSupply" connectionString="Data Source=.;Initial Catalog=pSupply;User ID=sa;Password=1234"/>
    <add name="ConString1" connectionString="Data Source=.;Initial Catalog=NEW1;Integrated Security=True"                           providerName="System.Data.SqlClient"/>
  </connectionStrings>
#>
$path = "D:\Documents\WindowsPowerShell\Scripts\"

$Web = $path + "ee22jun13.xml"
#$output = "connectionstring2.xml"
$New_Pass = "Welcome"
$Connection_String1 ="Data Source=JOHN.WORLD;User Id=peter;password=" + $New_Pass  
$Connection_String2 = "Data Source=WAYNE.WORLD;User ID=peter;password=" + $New_Pass
$xml = New-Object XML
$xml.Load($web)
# Change password
# If there 2 entries it will fail  
$cstrings = $xml.configuration.connectionstrings.add
foreach($cs in $cstrings) {}
$cstrings
<#
$xml.configuration.connectionStrings.Add[0] = $Connection_String1
$xml.configuration.connectionStrings.Add[1] = $Connection_String2
$xml.Save($Web)
cls
$Connection_String1
Get-Content $web
#>