function Get-FTP
{
    <#
    .Synopsis
        Gets files from FTP
    .Description
        Lists files on an FTP server, or downloads files
    .Example
        Get-FTP -FTP "ftp://edgar.sec.gov/edgar/full-index/1999/" -Download -Filter "*.idx", "*.xml" 
    #>
    param(
    # The url 
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Uri]$Ftp,

    # The credential used to connect to FTP.  If not provided, will connect anonymously.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential,

    # If set, will download files instead of discover them
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$Download,

    # The download path (by default, the downloads directory)
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$DownloadPath = "$env:UserProfile\Downloads",

    # If provided, will only download files that match the filter
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [string[]]$Filter,

    # If set, will download files that already have been downloaded and have the exact same file size.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$Force
    )

    begin {
        
        $folders = New-Object "system.collections.generic.queue[string]"
        function GetFtpStream($url, $method, $cred) {
                $ftp = [System.Net.WebRequest]::Create($url)
                if ($Credential)  {
                    $ftp.Credentials = $Credential.GetNetworkCredential()
                }
                $ftp.Method = $method
                $response = $ftp.GetResponse()
                  
                return New-Object IO.StreamReader $response.GetResponseStream()

        }
        function Get-FTPFile ($Source,$Target,$UserName,$Password) 
        { 
             $ftprequest = [System.Net.FtpWebRequest]::create($Source) 
             if ($Credential) {
                $ftprequest.Credentials = $Credential.GetNetworkCredential()
             }
             $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
             $ftprequest.UseBinary = $true 
             $ftprequest.KeepAlive = $false 
      
             $ftpresponse = $ftprequest.GetResponse() 
             $responsestream = $ftpresponse.GetResponseStream() 
             if (-not $responsestream) { return  } 
      
             $targetfile = New-Object IO.FileStream ($Target,[IO.FileMode]::Create) 
             [byte[]]$readbuffer = New-Object byte[] 1024 
      
             do{ 
                 $readlength = $responsestream.Read($readbuffer,0,1024) 
                 $targetfile.Write($readbuffer,0,$readlength) 
             } 
             while ($readlength -ne 0) 
      
             $targetfile.close() 
        }
    }
    process {
        $null = $folders.Enqueue("$ftp")
        while($folders.Count -gt 0){
            $fld = $folders.Dequeue()
        
            $newFiles = New-Object "system.collections.generic.list[string]"
            $newDirs = New-Object "system.collections.generic.list[string]"
            $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        
            $reader = GetFtpStream $fld $operation
    
            while (($line = $reader.ReadLine()) -ne $null) {
               [void]$newFiles.Add($line.Trim()) 
            }
            $reader.Dispose()


            $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
            $reader = GetFtpStream $fld $operation
    
            while (($line = $reader.ReadLine()) -ne $null) {
               [void]$newDirs.Add($line.Trim()) 
            }
            $reader.Dispose()
    
                
            foreach ($d in $newDirs) {
                $parts = ($d -split " " -ne '')
                if ($parts[4] -eq 4096 -or $parts[4] -eq 0) {
                    $newName = $parts[-1]
                    Write-Verbose "Enqueing Folder $($fld + $newName  + "/")"
                    $null = $folders.Enqueue($fld + $newName + "/")
                } else {
                    $updatedAt = $parts[-4..-2] -join ' ' -as [datetime]
                    
                    if (-not $updatedAt) { continue } 
                    $out = 
                        New-Object PSObject -Property @{
                            Ftp = $fld + $parts[-1]                        
                            Size = $parts[4]
                            UpdatedAt = $updatedAt
                        }

                    if ($filter) {
                        $matched = $false
                        foreach ($f in $filter) {
                            if ($parts[-1] -like "$f") {
                                $matched  = $true
                                break
                            }
                        }
                        if (-not $matched) {
                            continue
                        }
                    }
                    if ($download -or $psBoundParameters.DownloadPath) {
                        
                        $folderUri = [uri]($fld + $parts[-1])
                        
                        $downloadTo = Join-Path $DownloadPath $folderUri.LocalPath
                        $downloadDir  = Split-Path $downloadTo 
                        if (-not (Test-Path $downloadDir)) {
                            $null = New-Item -ItemType Directory $downloadDir
                        }

                        $item = Get-Item -Path $downloadTo -ErrorAction SilentlyContinue
                        if (($item.Length -ne $parts[4]) -or $Force) {
                            Get-FtpFile -Source $folderUri -Target $downloadTo                                                         
                        }
                        if (Test-Path $downloadTo) {
                            Get-Item $downloadTo
                        }
                        
                    } else {

                        $out
                    }
                    
                }
            }
            
        }
    }
}


