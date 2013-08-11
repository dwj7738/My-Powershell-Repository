##############################################################################
##
## Get-Answer
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Uses Bing Answers to answer your question

.EXAMPLE

Get-Answer "(5 + e) * sqrt(x) = Pi"
Calculation
(5+e )*sqrt ( x)=pi  : x=0.165676

.EXAMPLE

Get-Answer msft stock
Microsoft Corp (US:MSFT) NASDAQ
29.66  -0.35 (-1.17%)
After Hours: 30.02 +0.36 (1.21%)
Open: 30.09    Day's Range: 29.59 - 30.20
Volume: 55.60 M    52 Week Range: 17.27 - 31.50
P/E Ratio: 16.30    Market Cap: 260.13 B

#>

Set-StrictMode -Version Latest

$question = $args -join " "

function Main
{
    ## Load the System.Web.HttpUtility DLL, to let us URLEncode
    Add-Type -Assembly System.Web

    ## Get the web page into a single string with newlines between
    ## the lines.
    $encoded = [System.Web.HttpUtility]::UrlEncode($question)
    $url = "http://www.bing.com/search?q=$encoded"
    $text = (new-object System.Net.WebClient).DownloadString($url)

    ## Find the start of the answers section
    $startIndex = $text.IndexOf('<div class="ans">')

    ## The end is either defined by an "attribution" div
    ## or the start of a "results" div
    $endIndex = $text.IndexOf('<div class="sn_att2">')
    if($endIndex -lt 0) { $endIndex = $text.IndexOf('<div id="results">') }

    ## If we found a result, then filter the result
    if(($startIndex -ge 0) -and ($endIndex -ge 0))
    {
        ## Pull out the text between the start and end portions
        $partialText = $text.Substring($startIndex, $endIndex - $startIndex)

        ## Very fragile screen scraping here. Replace a bunch of
        ## tags that get placed on new lines with the newline
        ## character, and a few others with spaces.
        $partialText = $partialText -replace '<div[^>]*>',"`n"
        $partialText = $partialText -replace '<tr[^>]*>',"`n"
        $partialText = $partialText -replace '<li[^>]*>',"`n"
        $partialText = $partialText -replace '<br[^>]*>',"`n"
        $partialText = $partialText -replace '<span[^>]*>'," "
        $partialText = $partialText -replace '<td[^>]*>',"    "

        $partialText = CleanHtml $partialText

        ## Now split the results on newlines, trim each line, and then
        ## join them back.
        $partialText = $partialText -split "`n" |
            Foreach-Object { $_.Trim() } | Where-Object { $_ }
        $partialText = $partialText -join "`n"

        [System.Web.HttpUtility]::HtmlDecode($partialText.Trim())
    }
    else
    {
        "`nNo answer found."
    }
}

## Clean HTML from a text chunk
function CleanHtml ($htmlInput)
{
    $tempString = [Regex]::Replace($htmlInput, "(?s)<[^>]*>", "")
    $tempString.Replace("&nbsp&nbsp", "")
}

. Main
