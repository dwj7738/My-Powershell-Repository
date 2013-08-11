## .SYNOPSIS 
## Retrieves the list of Twitter usernames from 
## http://www.sqlsaturday.com/70/networking.aspx 
 
param( 
    ## The web page holding the twitter usernames 
    [Parameter()] 
    [URI] $Uri = "http://www.sqlsaturday.com/70/networking.aspx" 
) 
 
## Download the file 
$wc = New-Object System.Net.WebClient 
$htmlContent = $wc.DownloadString($uri) 
 
## Find all hyperlinks that are of the form: http://www.twitter.com/<username> 
$pattern = '<a href="http://www.twitter.com/([^"]*)"' 
$result = $htmlContent | Select-String -Pattern $pattern -AllMatches 
$usernames = $result.Matches | Foreach-Object { $_.Groups[1].Value } 
 
## Dirty data! Welcome to the internet! 
## Some of the URLs are incorrect, such as 
## http://www.twitter.com/http://twitter.com/<username> 
## If a username has a slash in it, just take everything after it. 
$usernames -replace ".*/(.*)",'$1'