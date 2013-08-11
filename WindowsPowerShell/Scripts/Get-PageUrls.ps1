##############################################################################
##
## Get-PageUrls
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##############################################################################

<#

.SYNOPSIS

Parse all of the URLs out of a given file.

.EXAMPLE

Get-PageUrls microsoft.html http://www.microsoft.com
Gets all of the URLs from HTML stored in microsoft.html, and converts relative
URLs to the domain of http://www.microsoft.com

.EXAMPLE

Get-PageUrls microsoft.html http://www.microsoft.com 'aspx$'
Gets all of the URLs from HTML stored in microsoft.html, converts relative
URLs to the domain of http://www.microsoft.com, and returns only URLs that end
in 'aspx'.

#>

param(
    ## The filename to parse
    [Parameter(Mandatory = $true)]
    [string] $Path,

    ## The URL from which you downloaded the page.
    ## For example, http://www.microsoft.com
    [Parameter(Mandatory = $true)]
    [string] $BaseUrl,

    [switch] $Images,
    
    ## The Regular Expression pattern with which to filter
    ## the returned URLs
    [string] $Pattern = ".*"
)

Set-StrictMode -Version Latest

## Load the System.Web DLL so that we can decode URLs
Add-Type -Assembly System.Web

## Defines the regular expression that will parse an URL
## out of an anchor tag.
$regex = "<\s*a\s*[^>]*?href\s*=\s*[`"']*([^`"'>]+)[^>]*?>"
if($Images)
{
    $regex = "<\s*img\s*[^>]*?src\s*=\s*[`"']*([^`"'>]+)[^>]*?>"
}

## Parse the file for links
function Main
{
    ## Do some minimal source URL fixups, by switching backslashes to
    ## forward slashes
    $baseUrl = $baseUrl.Replace("\", "/")

    if($baseUrl.IndexOf("://") -lt 0)
    {
        throw "Please specify a base URL in the form of " +
            "http://server/path_to_file/file.html"
    }

    ## Determine the server from which the file originated.  This will
    ## help us resolve links such as "/somefile.zip"
    $baseUrl = $baseUrl.Substring(0, $baseUrl.LastIndexOf("/") + 1)
    $baseSlash = $baseUrl.IndexOf("/", $baseUrl.IndexOf("://") + 3)

    if($baseSlash -ge 0)
    {
        $domain = $baseUrl.Substring(0, $baseSlash)
    }
    else
    {
        $domain = $baseUrl
    }


    ## Put all of the file content into a big string, and
    ## get the regular expression matches
    $content = [String]::Join(' ', (Get-Content $path))
    $contentMatches = @(GetMatches $content $regex)

    foreach($contentMatch in $contentMatches)
    {
        if(-not ($contentMatch -match $pattern)) { continue }
        if($contentMatch -match "javascript:") { continue }

        $contentMatch = $contentMatch.Replace("\", "/")

        ## Hrefs may look like:
        ## ./file
        ## file
        ## ../../../file
        ## /file
        ## url
        ## We'll keep all of the relative paths, as they will resolve.
        ## We only need to resolve the ones pointing to the root.
        if($contentMatch.IndexOf("://") -gt 0)
        {
            $url = $contentMatch
        }
        elseif($contentMatch[0] -eq "/")
        {
            $url = "$domain$contentMatch"
        }
        else
        {
            $url = "$baseUrl$contentMatch"
            $url = $url.Replace("/./", "/")
        }

        ## Return the URL, after first removing any HTML entities
        [System.Web.HttpUtility]::HtmlDecode($url)
    }
}

function GetMatches([string] $content, [string] $regex)
{
    $returnMatches = new-object System.Collections.ArrayList

    ## Match the regular expression against the content, and
    ## add all trimmed matches to our return list
    $resultingMatches = [Regex]::Matches($content, $regex, "IgnoreCase")
    foreach($match in $resultingMatches)
    {
        $cleanedMatch = $match.Groups[1].Value.Trim()
        [void] $returnMatches.Add($cleanedMatch)
    }

    $returnMatches
}

. Main
