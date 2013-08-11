function Get-Web {
    <#
    .Synopsis
        Gets content from the web, or parses web content.
    .Description
        Gets content from the web.  
        
        If -Tag is passed, extracts out tags from within the document.

        If -AsByte is passed, returns the response bytes
    .Example
       # Download the Microsoft front page and extract out links
       Get-Web -Url http://microsoft.com/ -Tag a
    .Example
       # Extract the rows from ConvertTo-HTML
       $text = Get-ChildItem | Select Name, LastWriteTime | ConvertTo-HTML | Out-String 
       Get-Web "tr" $text
    .Example
        # Extract all PHP elements from a directory of .php scripts
        Get-ChildItem -Recurse -Filter *.php | 
            Get-Web -Tag .\?php, \?
    .Example
        # Extract all asp tags from .asp files
        Get-ChildItem -Recurse | 
            Where-Object { '.aspx', '.asp'. '.ashx' -contains $_.Extension } |
            Get-Web -Tag .\%
    .Example
        # Get a list of all schemas from schema.org
        $schemasList = Get-Web -Url http://schema.org/docs/full.html -Tag a | 
            Where-Object { $_.Xml.href -like '/*' } | 
            ForEach-Object { "http://schema.org" + $_.xml.Href } 
            
    .Example
        # Extract out the example of a schema from schema.org        
        
        $schema = 'http://schema.org/Event'
        Get-Web -Url $schema -Tag pre | 
            Where-Object { $_.Xml.Class -like '*prettyprint*' }  | 
            ForEach-Object {
                Get-Web -Html $_.Xml.InnerText -AsMicrodata -ItemType $schema 
            }  
    .Example
        # List the top 1000 sites on the web:
        Get-Web "http://www.google.com/adplanner/static/top1000/" -Tag 'a' | 
            where-Object {$_.Tag -like "*_blank*" }  | 
            ForEach-Object {
                ([xml]$_.StartTag.Replace('"t', '" t')).a.href
            }         
    .Link
        http://schema.org
    #>
    
    [CmdletBinding(DefaultParameterSetName='HTML')]
    [OutputType([PSObject],[string])]
    param(
    # The tags to extract.
    [Parameter(        
        ValueFromPipelineByPropertyName=$true)]
    [string[]]$Tag,
    
    # If used with -Tag, -RequireAttribute will only match tags with a given keyword in the tag
    [string[]]$TextInTag,
     
    # The source HTML.
    [Parameter(Mandatory=$true,
        ParameterSetName='HTML',
        ValueFromPipelineByPropertyName=$true)]
    [string]$Html,    
    
    # The Url
    [Parameter(Mandatory=$true,
        Position=0,
        ParameterSetName='Url',
        ValueFromPipelineByPropertyName=$true)]

    [string]$Url,

    # Any parameters to the URL
    [Parameter(ParameterSetName='Url',
        Position=1,
        ValueFromPipelineByPropertyName=$true)]
    [Hashtable]$Parameter,
    
    # Filename
    [Parameter(Mandatory=$true,
        ParameterSetName='FileName',
        ValueFromPipelineByPropertyName=$true)]
    [Alias('Fullname')]
    [ValidateScript({$ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($_)})]
    [string]$FileName,    

    # The User Agent
    [Parameter(ParameterSetName='Url',
        ValueFromPipelineByPropertyName=$true)]
    [string]$UserAgent = "PowerShellPipeworks/2.0 Get-Web/2.0",
    
    # If set, will not show progress for long-running operations
    [Switch]$HideProgress,

    # If set, returns resutls as bytes
    [Alias('Byte', 'Bytes')]
    [Switch]$AsByte,

    # If set, returns results as XML
    [Alias('Xml')]
    [Switch]$AsXml,
    
    [Switch]$AsJson,
    
    # If set, extracts Microdata out of a page
    [Alias('Microdata')]
    [Switch]$AsMicrodata,
    
    # If set, will get back microdata from the page that matches an itemtype
    [string[]]$ItemType,
    
    # If set, extracts OpenGraph information out of a page
    [Switch]$OpenGraph,
    
    # If set, will extract all meta tags from a page
    [Switch]$MetaData,

    [string]$ContentType,
    
    [Parameter(ParameterSetName='Url',
        ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $WebCredential,
    
    
    [Parameter(ParameterSetName='Url',
        ValueFromPipelineByPropertyName=$true)]    
    [ValidateSet('GET','POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'TRACE', 'CONNECT')]
    [string]$Method = "GET",
    
    
    [Hashtable]$Header,
    
    $RequestBody,

    [Switch]
    $UseWebRequest
    )
    
    begin {
        $replacements = @{
            "<BR>" = "<BR />"
            "<HR>" = "<HR />"
            "&nbsp;" = " "
            '&macr;'='¯'
            '&ETH;'='Ð'
            '&para;'='¶'
            '&yen;'='¥'
            '&ordm;'='º'
            '&sup1;'='¹'
            '&ordf;'='ª'
            '&shy;'='­'
            '&sup2;'='²'
            '&Ccedil;'='Ç'
            '&Icirc;'='Î'
            '&curren;'='¤'
            '&frac12;'='½'
            '&sect;'='§'
            '&Acirc;'='â'
            '&Ucirc;'='Û'
            '&plusmn;'='±'
            '&reg;'='®'
            '&acute;'='´'
            '&Otilde;'='Õ'
            '&brvbar;'='¦'
            '&pound;'='£'
            '&Iacute;'='Í'
            '&middot;'='·'
            '&Ocirc;'='Ô'
            '&frac14;'='¼'
            '&uml;'='¨'
            '&Oacute;'='Ó'
            '&deg;'='°'
            '&Yacute;'='Ý'
            '&Agrave;'='À'
            '&Ouml;'='Ö'
            '&quot;'='"'
            '&Atilde;'='Ã'
            '&THORN;'='Þ'
            '&frac34;'='¾'
            '&iquest;'='¿'
            '&times;'='×'
            '&Oslash;'='Ø'
            '&divide;'='÷'
            '&iexcl;'='¡'
            '&sup3;'='³'
            '&Iuml;'='Ï'
            '&cent;'='¢'
            '&copy;'='©'
            '&Auml;'='Ä'
            '&Ograve;'='Ò'
            '&Aring;'='Å'
            '&Egrave;'='È'
            '&Uuml;'='Ü'
            '&Aacute;'='Á'
            '&Igrave;'='Ì'
            '&Ntilde;'='Ñ'
            '&Ecirc;'='Ê'
            '&cedil;'='¸'
            '&Ugrave;'='Ù'
            '&szlig;'='ß'
            '&raquo;'='»'
            '&euml;'='ë'
            '&Eacute;'='É'
            '&micro;'='µ'
            '&not;'='¬'
            '&Uacute;'='Ú'
            '&AElig;'='Æ'
            '&euro;'= "€"        
            '&mdash;' = '—'
        }

        $quotes = '"', "'"
        function Convert-Json
        {
            param([Parameter(ValueFromPipeline=$true)]
            [string]$Json,
            
            [switch]$FullLanguage)

            begin {
                function ConvertFrom-Hashtable
                {
                    param($results)
                    $psObject = New-Object PSObject
                    foreach ($key in $results.Keys) {
                        $result = $null
                        if ($results[$key] -is [Hashtable]) {
                            $result = ConvertFrom-Hashtable $results[$key]
                        } elseif ($results[$key] -is [Array]) {
                            $result = foreach ($result in $results[$key]){
                                if ($result -is [Hashtable]) {
                                    ConvertFrom-Hashtable $result
                                } else {
                                    $result
                                }
                            }
                        } else {
                            $result = $results[$key]
                        }

                        if ($key) {
                            $psObject.psObject.Properties.Add(
                               (New-Object Management.Automation.PSNoteProperty $key, $result)
                            )                        
                        }
                        

                        
                    }
                    $psobject
                }
            }
            process {
                
                $script = 
                $json -replace 
                    '“|”', '`"' -replace                            
                    '"\s{0,}:', '"=' -replace             
                    "\[", "$([Environment]::NewLine)@(" -replace 
                    "\]", ")" -replace 
                    ',\[', ", $([Environment]::NewLine)@(" -replace 
                    "\],",")," -replace 
                    '\{"', "@{$([Environment]::NewLine)`"" -replace 
                    "\[\]", "@()" -replace             
                    "=(\w)*(\[)", '=@(' -replace 
                    "=(\d{1,}),",'=$1;' -replace
                    "=(\d{1,}.\d{1,}),",'=$1;' -replace
                    "=-(\d{1,}.\d{1,}),",'=-$1;' -replace
                    "true", "`$true" -replace
                    "false", "`$false" -replace
                    "null", '$null' -replace 
                    "\]}", ")}" -replace 
                    "{", "@{" -replace 
                    '\\"', '`"' -replace 
                    "@@", "@" -replace 
                    '(["})]),', "`$1$([Environment]::NewLine)" -replace
                    '(\$true),', "`$1$([Environment]::NewLine)" -replace
                    '(\$false),', "`$1$([Environment]::NewLine)" -replace 
                    '(\$null),', "`$1$([Environment]::NewLine)" -replace
                    "(-{0,1})(\d{1,}),", "`$1`$2$([Environment]::NewLine)" 
                    
                   

                    
                $replacements = @(@{
                    Find = '}\s{1,}@{'
                    Replace = '},@{'
                })
                foreach ($r in $replacements) {
                    foreach ($f in $r.find) {
                        $regex =New-Object Regex $f, "Multiline, IgnoreCase"
                        $script = $regex.Replace($script , $r.Replace)
                    }            
                }

                if ($script.Startswith("["))
                {
                    $script = "@("  + $script.Substring(1).TrimEnd("]") + ")"
                }
                $results = $null   
                Write-Verbose $script
                if ($FullLanguage)  {
                    $results = Invoke-Expression "$script"
                } else {
                    $results = Invoke-Expression "data { $script }"
                }
                
                if ($results) {
                    foreach ($result in $results) {ConvertFrom-Hashtable $result } 
                }
            }        
        }
        Add-Type -AssemblyName System.Web


        $progressId  = Get-Random
    }
    
    process {
        
        if ($psCmdlet.ParameterSetName -eq 'URL') {  
            #Region Download URL
            $fullUrl = "$url"
            
                    

            $xmlHttp = New-Object -ComObject Microsoft.xmlhttp            
            
            if ($useWebRequest) {

                if ($Parameter -and ('PUT', 'POST' -notcontains $method)) {
                    $fullUrl += "?"
                    foreach ($param in $parameter.GetEnumerator()) {
                        $fullUrl += "$($param.key)=$([Web.HttpUtility]::UrlEncode($param.Value.ToString()))&"
                    }
                }

                $req = [Net.WebRequest]::Create("$fullUrl") 
            
                $req.Method = $Method;
                if ($psBoundParameters.ContentType) { 
                    $req.ContentType = $ContentType
                }                                               
            

                #$req.Headers.add("UserAgent", $UserAgent)
                if ($psBoundParameters.WebCredential) {
                    $req.Credentials = $WebCredential.GetNetworkCredential()
                }

                if ($header) {
                    foreach ($kv in $header.GetEnumerator()) {
                        if ($kv.Key -eq 'Accept') {
                            $req.Accept = $kv.Value
                        } elseif ($kv.Key -eq 'content-type') {
                            $req.ContentType = $kv.Value
                        } else {
                            $null = $req.Headers.add("$($kv.Key)", "$($kv.Value)")
                        }
                        
                    }
                }
            
                $RequestTime  = [DateTime]::Now
                if (-not $HideProgress) {
                    Write-Progress "Sending Web Request" $url -Id $progressId
                }
                $requestStream = try {
                    
                    
                    if ($Parameter -and ('PUT', 'POST' -contains $method)) {
                        if (-not $RequestBody) {
                            $RequestBody = ""
                        }
                        
                        $RequestBody += 
                            (@(foreach ($param in $parameter.GetEnumerator()) {
                                "$($param.key)=$([Uri]::EscapeDataString($param.Value.ToString()))"
                            }) -join '&')
                    
                    } else {
                        $paramStr = ""
                    }
                    if ($ContentType) {
                        $req.ContentType  = $ContentType
                    }
                    
                
                
                    if ($requestBody) {
                        if ($RequestBody -is [string]) {
                            if (-not $ContentType) {
                                $req.ContentType = 'application/x-www-form-urlencoded'
                            }
                            $bytes = [Text.Encoding]::UTF8.GetBytes($RequestBody)                            
                            $postDataBytes = $bytes -as [Byte[]]
                            $req.ContentLength = $postDataBytes.Length                 
                            $requestStream = $req.GetRequestStream()                                                
                            $requestStream.Write($postDataBytes, 0, $postDataBytes.Count)                        
                            $requestStream.Close()                                    
                        } elseif ($RequestBody -as [byte[]]) {
                            if (-not $ContentType) {
                                $req.ContentType = 'application/x-www-form-urlencoded'
                            }
                            $postDataBytes = $RequestBody -as [Byte[]]
                            $req.ContentLength = $postDataBytes.Length                 
                            
                            $requestStream = $req.GetRequestStream()                                                
                            if ($req.ContentLength -gt 256kb) {
                                if (-not $HideProgress) {
                                    Write-Progress "Uploading" $url -Id $progressId 
                                }
                                #$requestStream.Write($postDataBytes, 0, $postDataBytes.Count)                        
                                

                                $tLen = 0 
                                $chunkTotal = [Math]::Ceiling($postDataBytes.Count / 256kb)
                                for ($chunkCount = 0; $chunkCount -lt $chunkTotal; $chunkCount++) {
                                    if ($chunkCount -ne ($chunkTotal -1 )) {

                                        $arr = $postDataBytes[($chunkCount * 256kb)..(([uint32]($chunkCount + 1) * 256kb) - 1)]
                                        $tLen+=$arr.Length
                                    } else {
                                        $arr = $postDataBytes[($chunkCount * 256kb)..($postDataBytes.Length - 1)]
                                        $tLen+=$arr.Length
                                    }
                                    $requestStream.Write($arr, 0 , $arr.Length)                        

                                    if (-not $HideProgress) {
                                        $perc = $chunkCount * 100 / $chunkTotal
                                        Write-Progress "Uploading" $url -Id $progressId -PercentComplete $perc
                                    }
                                }
                                
                                if (-not $HideProgress) {
                                    Write-Progress "Uploading" $url -Id $progressId -Completed
                                }
                            } else {
                                
                                $requestStream.Write($postDataBytes, 0, $postDataBytes.Count)                        
                                
                            }
                            $requestStream.Close()                                    
                        }
                        
                    } elseif ($paramStr) {
                        $postData = "$($paramStr -join '&')"
                        $postDataBytes = [Text.Encoding]::UTF8.GetBytes($postData)
                        $req.ContentLength = $postDataBytes.Length                 
                        $requestStream = $req.GetRequestStream()
                        $requestStream.Write($postDataBytes, 0, $postDataBytes.Count)
                        
                        $requestStream.Close()
                    } elseif ($method -ne 'GET' -and $method -ne 'HEAD') {
                        $req.ContentLength = 0
                    } 
                } catch {
                    
                    if (-not ($_.Exception.HResult -eq -2146233087)) {
                        $_ | Write-Error
                        return    
                    } 
                    
                    
                }

                Write-Verbose "Getting $fullUrl"
                
                $responseIsError = $false

                $webresponse = 
                    try {
                        $req.GetResponse()
                    } catch {
                        $ex = $_
                        if ($ex.Exception.InnerException.Response) {                            
                            $streamIn = New-Object IO.StreamReader $ex.Exception.InnerException.Response.GetResponseStream()
                            $strResponse = $streamIn.ReadToEnd();                            
                            $streamIn.Close();                 
                            Write-Error $strResponse 
                            return
                        } else {
                            $ex | Write-Error
                            return
                        }
                        return
                        #
                    }
                if (-not $webResponse) { 
                    return 
                }
                $rs = $webresponse.GetResponseStream()

                
                <#
                if ($rs.CopyTo) {
                    $null = $rs.CopyTo($ms)                
                } else {
                    $byteBuffer = new-object byte[] 65536;
                    [Int]$bytesRead = 0
                    $finished = $false
                    while (-not $finished) {
                        $bytesRead = $rs.Read($byteBuffer, 0, $byteBuffer.Length)
                        if ($bytesRead -gt 0) {
                            $bytesWritten = $ms.Write($byteBuffer, 0, $bytesRead);
                        } else {
                            $finished = $true
                        }
                    }                
                }
                #>

                

                

            
                if ($AsByte) {
                    #$ms = New-Object IO.MemoryStream
                    $byteBuffer = new-object byte[] $webresponse.ContentLength;
                    [int]$ToRead = $webresponse.ContentLength
                    [int]$TotalRead = 0
                    [Int]$bytesRead = 0
                    while ($toRead -gt 0) {
                        $bytesRead = $rs.Read($byteBuffer, $TotalRead, 1kb)    

                        if ($bytesRead -eq 0) {
                            break
                        }
                        $TotalRead += $bytesRead
                        $ToRead -= $bytesRead
                    }

                    
                    #$null = $rs.CopyTo($ms)                
                    
                    $outBytes = $byteBuffer 
                    #New-Object byte[] $ms.Length
                    #$null = $ms.Write($outBytes, 0, $ms.Length);
                } else {
                    $streamIn = New-Object IO.StreamReader($rs);
                    $strResponse = $streamIn.ReadToEnd();
                    $html = $strResponse 
                    $streamIn.Close();                 
                }
                
                $rs.close()
                $rs.Dispose()

                if ($AsByte) {
                    return $outBytes
                }

            }
            # $req.CookieContainer

            if (! $html -and -not $UseWebRequest) {
                if ($WebCredential) {            
                    $xmlHttp.open("$Method", 
                        $fullUrl, 
                        $false, 
                        $WebCredential.GetNetworkCredential().Username, 
                        $WebCredential.GetNetworkCredential().Password)
                } else {
                    $xmlHttp.open("$Method", $fullUrl, $false)
                }
                $xmlHttp.setRequestHeader("UserAgent", $userAgent)
                if ($header) {
                    foreach ($kv in $header.GetEnumerator()) {
                        $xmlHttp.setRequestHeader("$($kv.Key)", $kv.Value)
                    }
                }
            
                if (-not $HideProgress) {
                    Write-Progress "Sending Web Request" $url -Id $progressId
                }
            
                if ($parameter -and ('PUT', 'POST' -contains $method)) {
                    $paramStr = foreach ($param in $parameter.GetEnumerator()) {
                        "$($param.key)=$([Web.HttpUtility]::UrlEncode($param.Value.ToString()))"
                    }

                    if ($Header.ContainsKey('ContentType')) {
                        $ContentType = $Header['ContentType']
                    } elseif ($Header.ContainsKey('Content-Type')) {
                        $ContentType = $Header['Content-Type']
                    }
                    if ($ContentType) {
                        $xmlHttp.SetRequestHeader("Content-Type","$ContentType")
                    } else {
                        $xmlHttp.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
                        
                    }


                    
                    

                    
                    if ($requestBody) {
                        $xmlHttp.Send("$requestBody")                        
                
                    } else {
                        $xmlHttp.Send("$($paramStr -join '&')")                        
                    }
                
                } else {
                    
                    $xmlHttp.Send($RequestBody)            
                }
                $requestTime = [Datetime]::Now
                while ($xmlHttp.ReadyState -ne 4) {
                    if (-not $hideProgress) {
                        Write-Progress "Waiting for response" $url -id $progressId
                    }
                    Start-Sleep -Milliseconds 10                
                }
            }


            $ResponseTime = [Datetime]::Now - $RequestTime  
            
            if (-not $hideProgress) {
                Write-Progress "Response received" $url -id $progressId
            }
            if ($xmlHttp.Status -like "2*") {
                Write-Verbose "Server Responded with Success $($xmlHttp.Status)"
            } elseif ($xmlHttp.Status -like "1*") {
                Write-Debug "Server Responded with Information $($xmlHttp.Status)"
            } elseif ($xmlHttp.Status -like "3*") {
                Write-Warning "Server wishes to redirect: $($xmlHttp.Status)"                
            } elseif ($xmlHttp.Status -like "4*") {
                
                $errorWithinPage = 
                    Get-Web -Html $xmlHttp.responseText -Tag span | 
                        Where-Object { $_.Tag -like '*ui-state-error*' }  | 
                        ForEach-Object { 
                            $short = $_.Tag.Substring($_.Tag.IndexOf(">") + 1); 
                            $short.Substring(0, $short.LastIndexOf("</")) 
                        }   
                
                $errorText = if ($errorWithinPage) {
                    $errorWithinPage
                } else {
                    $xmlHttp.MessageText
                }
                Write-Error "Server Responded with Error: $($xmlHttp.Status) - $($errorText)"
                return
            }
            #endregion Download URL

            if ($AsByte) {
                return $xmlHttp.ResponseBody
            } elseif (-not $UseWebRequest) {
                $html = $xmlHttp.ResponseText
            }
        } elseif ($psCmdlet.ParameterSetName -eq 'FileName') {
            if ($AsByte) {
                [IO.File]::ReadAllBytes($ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($FileName))
                return 
            }             
            $html = [IO.File]::ReadAllText($ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($FileName))            
        }
        
        if (-not $html) { return } 

        if ($AsXml) {
            $xHtml = [xml]$html
            return $xHtml
        }
        
        if ($AsJson) {
            Convert-Json -json $html -FullLanguage
            return
        }

        if (-not $Tag -or $AsMicrodata) {
            if ($AsByte) { 
                return [Text.Encoding]::Unicode.GetBytes($html)
            }
        }
               
        foreach ($r in $replacements.GetEnumerator()) {
            $l = 0 
            do {
                $l = $html.IndexOf($r.Key, $l, [StringComparison]"CurrentCultureIgnoreCase")
                if ($l -ne -1) {
                    $html = $html.Remove($l, $r.Key.Length)
                    $html = $html.Insert($l, $r.Value)
                }
            } while ($l -ne -1)         
        }
        
        if ($tag -and -not ($AsMicrodata -or $OpenGraph -or $MetaData -or $ItemType)) {
            $tryToBalance = $true
            
            if ($openGraph -or $metaData) {
                $tryToBalance  = $false
            }
 
            foreach ($htmlTag in $tag) {
                if (-not $htmlTag) { continue } 
                $r = New-Object Text.RegularExpressions.Regex ('</' + $htmlTag + '>'), ("Singleline", "IgnoreCase")
                $endTags = @($r.Matches($html))
                if ($textInTag) {
                    
                    $r = New-Object Text.RegularExpressions.Regex ('<' + $htmlTag + '[^>]*' + ($textInTag -join '[^>]*') + '[^>]*>'), ("Singleline", "IgnoreCase")
                } else {
                    $r = New-Object Text.RegularExpressions.Regex ('<' + $htmlTag + '[^>]*>'), ("Singleline", "IgnoreCase")
                }
                
                $startTags = @($r.Matches($html))
                $tagText = New-Object Collections.ArrayList
                $tagStarts = New-Object Collections.ArrayList
                if ($tryToBalance -and ($startTags.Count -eq $endTags.Count)) {
                    $allTags = $startTags + $endTags | Sort-Object Index   
                    $startTags = New-Object Collections.Stack
                    
                    foreach($t in $allTags) {
                        if (-not $t) { continue } 
                        
                        if ($t.Value -like "<$htmlTag*") {
                            $startTags.Push($t)
                        } else {
                            $start = try { $startTags.Pop() } catch {}
                            $null = $tagStarts.Add($start.Index)
                            $null  = $tagText.Add($html.Substring($start.Index, $t.Index + $t.Length - $start.Index))
                        }
                    }
                } else {
                    # Unbalanced document, use start tags only and make sure that the tag is self-enclosed
                    foreach ($_ in $startTags) {
                        if (-not $_) { continue } 
                        $t = "$($_.Value)"
                        if ($t -notlike "*/>") {
                            $t = $t.Insert($t.Length - 1, "/")
                        }
                        $null = $tagStarts.Add($t.Index)
                        $null  = $tagText.Add($t)    
                
                    } 
                }
            
                $tagCount = 0 
                foreach ($t in $tagText) {
                    if (-not $t) {continue }
                    $tagStartIndex = $tagStarts[$tagCount]
                    $tagCount++
                    # Correct HTML which doesn't quote the attributes so it can be coerced into XML
                    $inTag = $false
                    for ($i = 0; $i -lt $t.Length; $i++) {
                        
                        if ($t[$i] -eq "<") {
                            $inTag = $true
                        } else {
                            if ($t[$i] -eq ">") {
                                $inTag = $false
                            }
                        }
                        if ($inTag -and ($t[$i] -eq "=")) {
                            if ($quotes -notcontains $t[$i + 1]) {
                                $endQuoteSpot = $t.IndexOfAny(" >", $i + 1)
                                # Find the end of the attribute, then quote
                                $t = $t.Insert($i + 1, "'")
                                $t = $t.Insert($endQuoteSpot + 1, "'")                    
                                $i = $endQuoteSpot
                                if ($i -eq -1) {
                                    break
                                }
                            } else {
                                # Make sure the quotes are correctly formatted, otherwise,
                                # end the quotes manually
                                $whichQuote = $t[$i + 1]
                                $endQuoteSpot = $t.IndexOf($whichQuote, $i + 2)
                                $i = $endQuoteSpot
                                if ($i -eq -1) {
                                    break
                                } 
                            }
                        }
                    } 
                
                    $startTag = $t.Substring(0, $t.IndexOf(">") + 1)
                    if ($pscmdlet.ParameterSetName -eq 'Url') {
                        New-Object PsObject -Property @{
                            Tag= $t
                            StartTag = $startTag
                            StartsAt = $tagStartIndex
                            Xml = ($t -as [xml]).$htmlTag      
                            Source = $url
                        }
                    } else {
                        New-Object PsObject -Property @{
                            Tag= $t
                            StartTag = $startTag
                            StartsAt = $tagStartIndex
                            Xml = ($t -as [xml]).$htmlTag      
                        } 
                    }
                                 
                }
            }
        } elseif ($OpenGraph) {
            $metaTags = Get-Web -Html $html -Tag 'meta' 
            $outputObject = New-Object PSObject
            foreach ($mt in $metaTags) {
                if ($mt.Xml.Property -like "og:*") {
                    $propName = $mt.Xml.Property.Substring(3)
                    $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $mt.Xml.Content
                    if ($outputObject.psobject.properties[$propName]) {
                        $outputObject.psobject.properties[$propName].Value = 
                            @($outputObject.psobject.properties[$propName].Value) + $noteProperty.Value | Select-Object -Unique
                    } else {
                        try {
                            $null = Add-Member -InputObject $outputObject NoteProperty $noteProperty.name $noteProperty.Value -Force
                        } catch {
                            
                            Write-Error $_
                        }
                    }
                }
                
            }
            $null = $OutputObject.pstypenames.add('OpenGraph')
            $outputObject
        } elseif ($MetaData) {
            $titleTag= Get-Web -Html $html -Tag 'title'
            $titleText = $titleTag.xml.Trim()
            $metaTags = Get-Web -Html $html -Tag 'meta' 
            $outputObject = New-Object PSObject
            Add-Member NoteProperty Title $titleText -InputObject $outputObject
            foreach ($mt in $metaTags) {
                $propName = if ($mt.Xml.Property) {
                    $mt.Xml.Property
                } elseif ($mt.Xml.name -and $mt.Xml.Name -ne 'meta') {
                    $mt.Xml.name
                }
                
                if (-not $PropName) { continue } 
                $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $mt.Xml.Content
                if ($outputObject.psobject.properties[$propName]) {
                    $outputObject.psobject.properties[$propName].Value = 
                        @($outputObject.psobject.properties[$propName].Value) + $noteProperty.Value | Select-Object -Unique
                } else {
                    try {
                        $null = Add-Member -InputObject $outputObject NoteProperty $noteProperty.name $noteProperty.Value -Force
                    } catch {
                        
                        Write-Error $_
                    }
                }
            }               
            $null = $OutputObject.pstypenames.add('HTMLMetaData')
            if ($psBoundParameters.Url -and -not $outputObject.psobject.properties['Url']) {
                Add-Member -InputObject $outputObject NoteProperty Url $psboundParameters.Url
            }
            $outputObject
        } elseif ($AsMicrodata -or $ItemType) {
            $getInnerScope = {
                if (-not $knownTags[$htmlTag]) {
                    $r = New-Object Text.RegularExpressions.Regex ('<[/]*' + $htmlTag + '[^>]*>'), ("Singleline", "IgnoreCase")                    
                    $Tags = @($r.Matches($html))
                    $knownTags[$htmlTag] = $tags
                }
                
                $i = 0
                $myTagIndex = foreach ($_ in $knownTags[$htmlTag]) {
                    if ($_.Value -eq $targetValue -and $_.Index -eq $targetIndex) { 
                        $i
                    }
                    $i++
                }
                
                # Once the tag index is known, we start there and wait until the tags are balanced again
                $balance = 1
                for ($i = $myTagIndex + 1; $i -lt $knownTags[$htmlTag].Count; $i++) {
                    if ($knownTags[$htmlTag][$i].Value -like "<$htmlTag*"){
                        $balance++
                    } else {
                        $balance--
                    }
                    if ($balance -eq 0) {                                               
                        break
                    }                                        
                }
                
                if ($balance -eq 0 -and ($i -ne $knownTags[$htmlTag].Count)) {
                    $start = $knownTags[$htmlTag][$MyTagIndex].Index
                    $end = $knownTags[$htmlTag][$i].Index + $knownTags[$htmlTag][$i].Length
                    $innerScope = $html.Substring($start, $end-$start)            
                } else {
                    $innerScope = ""
                }
                
                $myTagAsXml = $knownTags[$htmlTag][$MyTagIndex].Value
                if ($myTagASXml -notlike "*itemscope=*") {
                    $myTagASXml  = $myTagASXml -ireplace 'itemscope', 'itemscope=""'
                }  
                try {
                    $myTagAsXml = [xml]($myTagAsXml.TrimEnd("/>") + "/>")
                } catch {
                    
                }


            }
            
            
                
            $itemScopeFinder = New-Object Text.RegularExpressions.Regex ('<(?<t>\w*)[^>]*itemscope[^>]*>'), ("Singleline", "IgnoreCase")
            $knownTags = @{}
            foreach ($matchInfo in $itemScopeFinder.Matches($html)) {
                if (-not $matchInfo)  { continue }                                
                $htmlTag = $matchInfo.Groups[1].Value        
                $targetValue = $matchInfo.Groups[0].Value        
                $targetIndex = $matchInfo.Groups[0].Index
                $innerScopeStart = 0 
                . $getInnerScope                                 

                $innerHtml = "$innerScope"
                $itemPropFinder = New-Object Text.RegularExpressions.Regex ('<(?<t>\w*)[^>]*itemprop[^>]*>'), ("Singleline", "IgnoreCase")
                $outputObject = New-Object PSObject 
                $outputObject.pstypenames.clear()
                foreach ($itemTypeName in $myTagAsXml.firstchild.itemtype -split " ") {                                    
                    if (-not $itemTypeName) { continue }                    
                    $null = $outputObject.pstypenames.add($itemTypeName)                    
                }
                
                # If we've asked for a specific item type, and this isn't it, continue
                if ($ItemType) {
                    $found = foreach ($tn in $outputObject.pstypenames) {
                        if ($ItemType -contains $tn) {
                            $true
                        }                        
                    }
                    if (-not $found) {                                         
                        continue
                    }
                }
                
                
                
                if ($myTagAsXml.firstChild.itemId) {
                    $itemID = New-Object Management.Automation.PSNoteProperty "ItemId", $myTagAsXml.firstChild.itemId
                    $null = $outputObject.psobject.properties.add($itemID)
                }
                
                $avoidRange = @()
                
                foreach ($itemPropMatch in $itemPropFinder.Matches($innerScope)) {
                    $propName = ""
                    $propValue = ""
                    $htmlTag = $itemPropMatch.Groups[1].Value        
                    $targetValue = $itemPropMatch.Groups[0].Value   
                    if ($itemPropMatch.Groups[0].Value -eq $matchInfo.Groups[0].Value) {
                        # skip relf references so we don't infinitely recurse
                        continue
                    }
                    $targetIndex = $matchInfo.Groups[0].Index + $itemPropMatch.Groups[0].Index                                                                 
                    if ($avoidRange -contains $itemPropMatch.Groups[0].Index) {
                        continue
                    }
                    . $getInnerScope 
                    $propName = $myTagAsXml.firstchild.itemprop
                    if (-not $propName) { 
                        Write-Debug "No Property Name, Skipping"
                        continue
                    }

                    if (-not $innerScope) {                 
                        
                        # get the data from one of a few properties.  href, src, or content
                        $fixedXml = try { [xml]($itemPropMatch.Groups[0].Value.TrimEnd("/>") + "/>") } catch { }
                        $propName = $fixedxml.firstchild.itemprop
                        $propValue = if ($fixedXml.firstchild.href) {
                            $fixedXml.firstchild.href
                        } elseif ($fixedXml.firstchild.src) {
                            $fixedXml.firstchild.src
                        } elseif ($fixedXml.firstchild.content) {
                            $fixedXml.firstchild.content
                        } elseif ('p', 'span', 'h1','h2','h3','h4','h5','h6' -contains $htmlTag) {
                            $innerTextWithoutspaces = ([xml]$innerScope).innertext -replace "\s{1,}", " "
                            $innerTextWithoutSpaces.TrimStart()                                    
                        }
                        if ($propName) { 
                            try {
                            $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $propValue
                            } catch {
                                Write-Debug "Could not create note property"
                            }
                        }
                        
                    } else {
                        if ($innerScope -notlike '*itemscope*') {                            
                            $innerScopeXml = try { [xml]$innerScope } catch { } 
                            
                            if ($innerScopeXml.firstChild.InnerXml -like "*<*>") {
                                $propValue = if ($myTagAsXml.firstchild.href) {
                                     $myTagAsXml.firstchild.href
                                } elseif ($myTagAsXml.firstchild.src) {
                                    $myTagAsXml.firstchild.src
                                } elseif ($myTagAsXml.firstchild.content) {
                                    $myTagAsXml.firstchild.content
                                } elseif ('p', 'span', 'h1','h2','h3','h4','h5','h6' -contains $htmlTag) {
                                    $innerTextWithoutspaces = ([xml]$innerScope).innertext -replace "\s{1,}", " "
                                    $innerTextWithoutSpaces.TrimStart()                                    
                                } else {
                                    $innerScope
                                }
                                try {
                                    $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $propValue
                                } catch {
                                    Write-Debug "Could not create note property"
                                }
                            } else {
                                $innerText = $innerScope.Substring($itemPropMatch.Groups[0].Value.Length)
                                $innerText = $innerText.Substring(0, $innerText.Length - "</$htmlTag>".Length)
                                $innerTextWithoutspaces = $innertext -replace "\s{1,}", " "
                                $innerTextWithoutSpaces = $innerTextWithoutSpaces.TrimStart()
                                try {
                                    $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $innerTextWithoutSpaces
                                } catch {
                                    Write-Debug "Could not create note property"
                                }
                            }
                            
                        } else {
                            # Keep track of where this item was seen, so everything else can skip nested data
                            $avoidRange +=  $itemPropMatch.Groups[0].Index..($itemPropMatch.Groups[0].Index + $innerScope.Length)
                            
                            $propValue = Get-Web -Html $innerScope  -Microdata
                            $noteProperty = New-Object Management.Automation.PSNoteProperty $propName, $propValue
                        }
                        
                        $innerItemHtml = $innerScope    
                    }
                    if ($outputObject.psobject.properties[$propName]) {
                        if ($noteProperty.Value -is [string]) {
                            $outputObject.psobject.properties[$propName].Value = 
                                @($outputObject.psobject.properties[$propName].Value) + $noteProperty.Value | Select-Object -Unique
                        } else {
                            $outputObject.psobject.properties[$propName].Value = 
                                @($outputObject.psobject.properties[$propName].Value) + $noteProperty.Value 
                        }
                    } else {
                        try {
                            $null = Add-Member -InputObject $outputObject NoteProperty $noteProperty.name $noteProperty.Value -Force
                        } catch {
                            
                            Write-Error $_
                        }
                    }
                    
                    
                    #$propName, $propValue                                                           
                }    
                if ($psBoundParameters.Url -and -not $outputObject.psobject.properties['Url']) {
                    Add-Member -InputObject $outputObject NoteProperty Url $psboundParameters.Url
                }
                $outputObject                           
            }
            # In this case, construct a regular expression that finds all itemscopes
            # Then create another regular expression to find all itemprops
            # Walk thru the combined list
        } else {
            $Html | 
                Add-Member NoteProperty ResponseTime $responseTime -PassThru |
                Add-Member NoteProperty RequestTime $requestTime -PassThru
        }        
    }
}
