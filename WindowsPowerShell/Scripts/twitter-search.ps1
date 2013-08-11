$cutoff = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')

$url = "http://search.twitter.com/search.atom?q=nbcfail&rpp=400&result_type=recent&since_id=$cutoff"

$xml = New-Object xml
$xml.load($url)
$xml.feed.entry | 
 # Where-Object { $_.Title -like '*DE-NI*' } | 
  Select-Object -ExpandProperty Title
