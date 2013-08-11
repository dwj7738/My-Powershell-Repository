$NumDays = 0
$LogDir = ".\User-Accounts.csv"
$currentDate = [System.DateTime]::Now
$currentDateUtc = $currentDate.ToUniversalTime()
$lltstamplimit = $currentDateUtc.AddDays(- $NumDays)
$lltIntLimit = $lltstampLimit.ToFileTime()
$adobjroot = [adsi]''
$objstalesearcher = New-Object System.DirectoryServices.DirectorySearcher($adobjroot)
$objstalesearcher.filter = "(&(objectCategory=person)(objectClass=user)(lastLogonTimeStamp<=" + $lltIntLimit + "))"
$users = $objstalesearcher.findall() | select `
@{e={$_.properties.cn};n='Display Name'},`
@{e={$_.properties.samaccountname};n='Username'},`
@{e={[datetime]::FromFileTimeUtc([int64]$_.properties.lastlogontimestamp[0])};n='Last Logon'},`
@{e={[string]$adspath=$_.properties.adspath;$account=[ADSI]$adspath;$account.psbase.invokeget('AccountDisabled')};n='Account Is Disabled'}
$users | Export-CSV -NoType $LogDir
