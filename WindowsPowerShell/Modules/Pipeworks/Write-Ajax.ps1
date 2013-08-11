function Write-Ajax
{
    <#
    .Synopsis
        Writes AJAX  
    .Description
        Writes AJAX.  This will execute the URL and replace the contents of
        the HTML element with the ID $updateId with the contents of the returned document 
        
    #>
    [OutputType([string])]
    param(       
    # The URL that will return updated contents
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Uri]$Url,    
    
    # The method to use for the request
    [ValidateSet("GET", "POST")]
    [string]$Method = "GET",
    
    # The ID to automatically update    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$UpdateId,
    
    # One or more input query values.
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$InputQuery,
    
    # The InputIDs the provide the query values.
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$InputId,
    
    # The name of the generated function.  If this is not provided, it will be set automatically from the URL
    [string]$Name,
    
    # Any post data
    [string]$PostData,
            
    # The Property to update on the update element
    [string]$UpdateProperty = "innerHTML",
    
    # If set, will output the ajax chunk in a <script> tag </script>
    [switch]$IncludeScriptTag,
    
    # If set, will escape the output content.  
    # If generating web pages with Write-Ajax to display to the user, instead of run in the browser, use -Escape
    [Switch]$Escape,
        
    # Runs one or more javascript functions when an ajax call completes, but before the property is set
    [string[]]
    $WhenResultReceived,                
    
    # Runs one or more javascript functions when an ajax call is made 
    [string[]]
    $WhenRequestMade,      
    
    # Runs one or more javascript functions when before an ajax call is made 
    [string[]]
    $BeforeRequestMade,           
    
    # Runs one or more javascript functions when an ajax call completes and has set a property
    [string[]]
    $ThenRun                
    )
    
    process {
        if (-not $psBoundParameters.Name) {
            $UrlFunctionName = $url.ToString()
            if ($urlFunctionName.Contains("?")) {
                $UrlFunctionName = $UrlFunctionName.Substring(0 ,$urlFunctionName.IndexOf("?")) 
            }
            $UrlFunctionName = $UrlFunctionName.Replace("/","_slash_").Replace("\","_backslash_").Replace(":", "_colon_").Replace(".", "_dot_").Replace("-","_")            
            $name = $UrlFunctionName
        }
        $fullUrl = $url
        $updateQueryData = ""
        if ($inputQuery) {
            for ($i = 0; $i -lt $InputQuery.Count; $i++) {
                if (@($inputId)[$i]) {
                    $updateQueryData += "
    if (document.getElementById('$($inputId[$i])').value.length != 0)  
    {
        if (queryData.length > 0) {
            queryData = queryData + '&$($inputQuery[$i])=' + encodeURIComponent(urldocument.getElementById('$($inputId[$i])').value); 
        } else {
            queryData = '$($inputQuery[$i])=' + encodeURIComponent(document.getElementById('$($inputId[$i])').value); 
        }    
    }
"                    
                }                                        
            }
        }             
        if ($updateQueryData) {   
            Write-Verbose $updateQueryData
        }
        $xmlHttpVar = "xmlHttp${$Name}"
        if (-not $psBoundParameters.Name) {
            $Name = "update${UpdateId}From_${Name}"
        }
            
$ajaxFunction = @"
function ${name}() {
    var $xmlHttpVar;
    var url = "$url";
    var queryData = "$postData";
    var method = '$($method.ToUpper())';
    if (window.XMLHttpRequest) 
    {
        // code for IE7+, FireFox, Chrome, Opera, Safari
        $xmlHttpVar = new XMLHttpRequest();
    } else 
    {
        // code for IE5, IE6
       $xmlHttpVar = new ActiveXObject("Microsoft.XMLHTTP");
    }
    
    $updateQueryData
    
    if (method == 'GET' && queryData.length > 0) {
        if (url.indexOf("?") != -1) {
            url = url + "&" + queryData;
        } else {
            url = url + "?" + queryData;
        }
    }           
    
    element = document.getElementById("$UpdateId");    
    if (element.nodeName  == 'IFRAME') {
        element.src = url
    } 
    
    $xmlHttpVar.onreadystatechange = function() {
        if (${xmlHttpVar}.readyState == 4) {
            if (${xmlHttpVar}.status == 200) {
                
                responseData = $xmlHttpVar.responseText;
                $(if ($escape) { 'responseData = escape(responseData)'})                                
                $(if ($WhenResultReceived) { $WhenResultReceived -join (';' + [Environment]::NewLine) + (' ' * 12) }) 
                document.getElementById("$UpdateId").${UpdateProperty}= responseData;                                
                $(if ($thenRun) { $thenRun -join (';' + [Environment]::NewLine) + (' ' * 12) })    
            } else {
                document.getElementById("$UpdateId").${UpdateProperty}= $xmlHttpVar.Status;
            }
        } else {
            if (${xmlHttpVar}.readyState != 1) {
                document.getElementById("$UpdateId").${UpdateProperty}= $xmlHttpVar.readyState;
            } else {
                $(if ($WhenRequestMade) { $WhenRequestMade -join (';' + [Environment]::NewLine) + (' ' * 12) }) 
            }            
        }
    }
    $(if ($BeforeRequestMade) { $BeforeRequestMade -join (';' + [Environment]::NewLine) + (' ' * 12) }) 
    $xmlHttpVar.open(method, url, true);    
    if (method == 'POST') {
        $xmlHttpVar.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        $xmlHttpVar.setRequestHeader("Content-length", querydata.length);
        $xmlHttpVar.setRequestHeader("Connection", "close");
        $xmlHttpVar.send(queryData);    
    } else {
        $xmlHttpVar.send();
    }    
    
}            
"@        

        if ($IncludeScriptTag) {
            @"
<script type='text/javascript'>
$ajaxFunction
</script>
"@
        } else {
$ajaxFunction            
        }
    }
}
