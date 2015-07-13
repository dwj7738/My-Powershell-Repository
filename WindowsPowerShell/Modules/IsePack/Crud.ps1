function Add-PowerShellIcicle {
    <#
    .Synopsis
        Adds items to IsePack PowerShellIcicle
    .Description
        Adds PowerShellIcicles 
    .Example
        Add-PowerShellIcicle
    .Link
        Set-AzureTable
    #>
    param(
    
    <#     
    The name of the icicle
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    Any keywords for the icicle
                 
    #>
    [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Keyword,
    <#     
    A description of the icicle
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The icicle content
    |LinesForInput 10             
    #>
    [Parameter(Mandatory=$true, Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Icicle
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Keyword",
            "Description",
            "Icicle"
    }

    
    process {
        foreach ($v in 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer') {
            $null = $psBoundParameters.Remove($v)
        }
        $UserPartition = $partition
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('IcicleInfo')
        $bigItems = $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force -PassThru
            }
        
        $found = & { $false} 
            
        if (-not $found) {
            $table = 'IsePack'
            $partition = 'PowerShellIcicle'
            $rowKey = . { "{0:x}" -f (Get-Random) }
            $toInput | 
                Set-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellIcicle' -RowKey $rowKey -PassThru
        }
    }            
            
    
    
}

Set-Alias New-PowerShellIcicle Add-PowerShellIcicle
Set-Alias Create-PowerShellIcicle Add-PowerShellIcicle

try { 
    Export-ModuleMember -Function Add-PowerShellIcicle -Alias New-PowerShellIcicle,Create-PowerShellIcicle -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Get-PowerShellIcicle {
    <#
    .Synopsis
        Gets IcicleInfo items from IsePack PowerShellIcicle
    .Description
        Gets PowerShellIcicles
    .Example
        Get-PowerShellIcicle
    .Example
        Get-PowerShellIcicle 'search term'
    .Example
        Get-PowerShellIcicle -ExactName 'exact name'
    .Example
        Get-PowerShellIcicle -ExactName 'exact name'
    .Link
        Get-AzureTable
    .Link
        Search-AzureTable
    .Link
        Write-Crud
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
    # The keyword to find within the items
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    
    [string]
    $Keyword,

    # The properties to return back from each item
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]    
    [string[]]
    $Select,
    
    # Find an item with this exact name
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    
    [string]
    $ExactName,
    
    # Find an item in this exact row
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [Parameter(Mandatory=$true,ParameterSetName='All',ValueFromPipelineByPropertyName=$true)]
    [switch]
    $All,
    
    
    
    
    
    
    
    # If set, will exclude table information
    [switch]    
    $ExcludeTableInfo    
    )
    
    begin {
        $unpackIt = {
            $DoNotConvertMarkdown = $true;
                    
            $item = $_
            $item.psobject.properties |                         
                Where-Object { 
                    $_.Value -and
                    ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                    (-not $_.Value.ToString().Contains(' ')) 
                }|                        
                ForEach-Object {
                    try {
                        $expanded = Expand-Data -CompressedData $_.Value
                        $item | Add-Member NoteProperty $_.Name $expanded -Force
                    } catch{
                        Write-Verbose $_
                    
                    }
                }
                
            if (-not $DoNotConvertMarkdown) {                 
                $item.psobject.properties |                         
                    Where-Object { 
                        ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                        (-not $_.Value.ToString().Contains('<')) 
                    }|                                   
                    ForEach-Object {
                        try {
                            $fromMarkdown = ConvertFrom-Markdown -Markdown $_.Value
                            $item | Add-Member NoteProperty $_.Name $fromMarkdown -Force
                        } catch{
                            Write-Verbose $_
                        
                        }
                    }
            }
            $item     
            
        
        }
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        
    }
    
    process {
        $selectIt = @{
            ExcludeTableInfo=$ExcludeTableInfo
            StorageAccount = $storageAccount
            StorageKey=  $storageKey
        }
        if ($select) {
            $selectIt['Select'] = $select
        }
        if ($psCmdlet.ParameterSetName -eq 'All') {
            
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellIcicle' } @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'Keyword') {
            if ($keyword.Trim() -eq '*') {
                throw "Keyword $keyword is too broad"
                return
            }

            if (-not $select) {
                $select = 'Name', 'Description', 'RowKey', 'PartitionKey'
            } else {
                $select += 'RowKey', 'PartitionKey'
                $select = $select | Select-Object -Unique
            }
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellIcicle' } -Select $select| 
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                } |
                Get-AzureTable -TableName 'IsePack' |
                 
                ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ExactName') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and Name eq '$ExactName'" @selectIt|
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'RowKey') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and RowKey eq '$RowKey'" @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ByUserID')  {            
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and UserID eq '$UserID'" @selectIt |
             
            ForEach-Object $unpackIt            
        }  elseif ($psCmdlet.ParameterSetName -eq 'ReadCode')  {            
            $readCodeFound = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq '' and ReadCode eq '$ReadCode'"
            $allReadings = foreach ($rcF in $readCodeFound) {
                if (-not $rcf) {continue }
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and  eq '$($rcf.RowKey)'"
            }
            $allReadings |                
                 
                ForEach-Object $unpackIt            
        } elseif ($psCmdlet.ParameterSetName -eq 'MyItem')  {
            if ($session -and $session['User'].UserID) {
                if (-not $keyword) { $keyword = '*' } 
                if ($exactName) { $keyword = $exactName } 

                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and UserID eq '$($session['User'].UserID)'" @selectIt |
                 
                ForEach-Object $unpackIt |
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                }
            } elseif ($env:UserName) {
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and UserID eq '$($env:UserName)'" @selectIt |
                 
                ForEach-Object $unpackIt
            }                        
        }
    }
}

Set-Alias Read-PowerShellIcicle Get-PowerShellIcicle
Set-Alias Search-PowerShellIcicle Get-PowerShellIcicle

try { 
    Export-ModuleMember -Function Get-PowerShellIcicle -Alias Read-PowerShellIcicle,Search-PowerShellIcicle -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Update-PowerShellIcicle {
    <#
    .Synopsis
        Updates items in IsePack PowerShellIcicle
    .Description
        Updates PowerShellIcicles  
    .Example
        Get-PowerShellIcicle -ExactName 'A Specific Item' | 
            Update-PowerShellIcicle -Description 'A New Description'
    .Link
        Update-AzureTable
    #>
    param(    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [switch]
    $Merge,
    
    
    <#     
    The name of the icicle
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    Any keywords for the icicle
                 
    #>
    [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Keyword,
    <#     
    A description of the icicle
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The icicle content
    |LinesForInput 10             
    #>
    [Parameter(Mandatory=$true, Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Icicle
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Keyword",
            "Description",
            "Icicle"
    }

    
    process {
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('IcicleInfo')
        $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force 
            }
                    
        $found = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellIcicle' and RowKey eq '$RowKey'" |
            Where-Object {
                $_.PartitionKey -eq 'PowerShellIcicle'
            }
            
        if ($found) {
            if ($found.UserId -and ($toInput.UserId -ne $found.UserId)) {
                Write-Error 'Item does not belong to you'
                return            
            }
            $row = $found.rowKey
            $null = $toInput.psObject.Properties.Remove('Merge')
            $null = $toInput.psObject.Properties.Remove('RowKey')
            
            $toInput | 
                Update-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellIcicle' -RowKey $rowKey -Value { $_ } -Merge:$merge -PassThru
        }
    }            
            
    
    
}

Set-Alias Set-PowerShellIcicle Update-PowerShellIcicle

try { 
    Export-ModuleMember -Function Update-PowerShellIcicle -Alias Set-PowerShellIcicle -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Remove-PowerShellIcicle 
{    
    <#
    .Synopsis
        Removes items from IsePack PowerShellIcicle
    .Description
        Updates PowerShellIcicles
    .Example
        Get-PowerShellIcicle -ExactName 'A Specific Item' | 
            Remove-PowerShellIcicle 
    .Link
        Remove-AzureTable
    #>        
    [CmdletBinding(DefaultParameterSetName='RowKey',SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    [string]
    $Keyword,
    
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    [string]
    $ExactName,
    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey        
    )
    
    process {                        
        $getParams = @{} + $psBoundParameters
        $getParams.Remove('WhatIf')
        $getParams.Remove('Confirm')
        if (-not $psBoundParameters.confirm -or ($psBoundParameters.Confirm -eq $false)) {
            if (-not $psBoundParameters.whatIf) {
                $confirmImpact = 'None'
            }
        }
        Get-PowerShellIcicle @getParams |
            Where-Object {
                $item = $_
                $toInput = New-Object PSObject
                
                
                if (-not $item.UserId) { return $true } 
                if ($item.UserId -eq $toInput.UserId) {
                    return $true
                }                
            } | 
            Remove-AzureTable 
    }
}

Set-Alias Delete-PowerShellIcicle Remove-PowerShellIcicle

try { 
    Export-ModuleMember -Function Remove-PowerShellIcicle -Alias Delete-PowerShellIcicle -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}

function Add-PowerShellWalkthru {
    <#
    .Synopsis
        Adds items to IsePack PowerShellWalkthru
    .Description
        Adds PowerShellWalkthrus 
    .Example
        Add-PowerShellWalkthru
    .Link
        Set-AzureTable
    #>
    param(
    
    <#     
    The name of the walkthru
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    Any keywords for the walkthru
                 
    #>
    [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Keyword,
    <#     
    A description of the walkthru
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Keyword",
            "Description"
    }

    
    process {
        foreach ($v in 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer') {
            $null = $psBoundParameters.Remove($v)
        }
        $UserPartition = $partition
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('IseWalkthru')
        $bigItems = $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force -PassThru
            }
        
        $found = & { $false} 
            
        if (-not $found) {
            $table = 'IsePack'
            $partition = 'PowerShellWalkthru'
            $rowKey = . { "{0:x}" -f (Get-Random) }
            $toInput | 
                Set-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellWalkthru' -RowKey $rowKey -PassThru
        }
    }            
            
    
    
}

Set-Alias New-PowerShellWalkthru Add-PowerShellWalkthru
Set-Alias Create-PowerShellWalkthru Add-PowerShellWalkthru

try { 
    Export-ModuleMember -Function Add-PowerShellWalkthru -Alias New-PowerShellWalkthru,Create-PowerShellWalkthru -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Get-PowerShellWalkthru {
    <#
    .Synopsis
        Gets IseWalkthru items from IsePack PowerShellWalkthru
    .Description
        Gets PowerShellWalkthrus
    .Example
        Get-PowerShellWalkthru
    .Example
        Get-PowerShellWalkthru 'search term'
    .Example
        Get-PowerShellWalkthru -ExactName 'exact name'
    .Example
        Get-PowerShellWalkthru -ExactName 'exact name'
    .Link
        Get-AzureTable
    .Link
        Search-AzureTable
    .Link
        Write-Crud
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
    # The keyword to find within the items
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    
    [string]
    $Keyword,

    # The properties to return back from each item
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]    
    [string[]]
    $Select,
    
    # Find an item with this exact name
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    
    [string]
    $ExactName,
    
    # Find an item in this exact row
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [Parameter(Mandatory=$true,ParameterSetName='All',ValueFromPipelineByPropertyName=$true)]
    [switch]
    $All,
    
    
    
    
    
    
    
    # If set, will exclude table information
    [switch]    
    $ExcludeTableInfo    
    )
    
    begin {
        $unpackIt = {
            $DoNotConvertMarkdown = $true;
                    
            $item = $_
            $item.psobject.properties |                         
                Where-Object { 
                    $_.Value -and
                    ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                    (-not $_.Value.ToString().Contains(' ')) 
                }|                        
                ForEach-Object {
                    try {
                        $expanded = Expand-Data -CompressedData $_.Value
                        $item | Add-Member NoteProperty $_.Name $expanded -Force
                    } catch{
                        Write-Verbose $_
                    
                    }
                }
                
            if (-not $DoNotConvertMarkdown) {                 
                $item.psobject.properties |                         
                    Where-Object { 
                        ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                        (-not $_.Value.ToString().Contains('<')) 
                    }|                                   
                    ForEach-Object {
                        try {
                            $fromMarkdown = ConvertFrom-Markdown -Markdown $_.Value
                            $item | Add-Member NoteProperty $_.Name $fromMarkdown -Force
                        } catch{
                            Write-Verbose $_
                        
                        }
                    }
            }
            $item     
            
        
        }
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        
    }
    
    process {
        $selectIt = @{
            ExcludeTableInfo=$ExcludeTableInfo
            StorageAccount = $storageAccount
            StorageKey=  $storageKey
        }
        if ($select) {
            $selectIt['Select'] = $select
        }
        if ($psCmdlet.ParameterSetName -eq 'All') {
            
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellWalkthru' } @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'Keyword') {
            if ($keyword.Trim() -eq '*') {
                throw "Keyword $keyword is too broad"
                return
            }

            if (-not $select) {
                $select = 'Name', 'Description', 'RowKey', 'PartitionKey'
            } else {
                $select += 'RowKey', 'PartitionKey'
                $select = $select | Select-Object -Unique
            }
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellWalkthru' } -Select $select| 
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                } |
                Get-AzureTable -TableName 'IsePack' |
                 
                ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ExactName') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and Name eq '$ExactName'" @selectIt|
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'RowKey') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and RowKey eq '$RowKey'" @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ByUserID')  {            
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and UserID eq '$UserID'" @selectIt |
             
            ForEach-Object $unpackIt            
        }  elseif ($psCmdlet.ParameterSetName -eq 'ReadCode')  {            
            $readCodeFound = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq '' and ReadCode eq '$ReadCode'"
            $allReadings = foreach ($rcF in $readCodeFound) {
                if (-not $rcf) {continue }
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and  eq '$($rcf.RowKey)'"
            }
            $allReadings |                
                 
                ForEach-Object $unpackIt            
        } elseif ($psCmdlet.ParameterSetName -eq 'MyItem')  {
            if ($session -and $session['User'].UserID) {
                if (-not $keyword) { $keyword = '*' } 
                if ($exactName) { $keyword = $exactName } 

                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and UserID eq '$($session['User'].UserID)'" @selectIt |
                 
                ForEach-Object $unpackIt |
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                }
            } elseif ($env:UserName) {
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and UserID eq '$($env:UserName)'" @selectIt |
                 
                ForEach-Object $unpackIt
            }                        
        }
    }
}

Set-Alias Read-PowerShellWalkthru Get-PowerShellWalkthru
Set-Alias Search-PowerShellWalkthru Get-PowerShellWalkthru

try { 
    Export-ModuleMember -Function Get-PowerShellWalkthru -Alias Read-PowerShellWalkthru,Search-PowerShellWalkthru -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Update-PowerShellWalkthru {
    <#
    .Synopsis
        Updates items in IsePack PowerShellWalkthru
    .Description
        Updates PowerShellWalkthrus  
    .Example
        Get-PowerShellWalkthru -ExactName 'A Specific Item' | 
            Update-PowerShellWalkthru -Description 'A New Description'
    .Link
        Update-AzureTable
    #>
    param(    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [switch]
    $Merge,
    
    
    <#     
    The name of the walkthru
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    Any keywords for the walkthru
                 
    #>
    [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Keyword,
    <#     
    A description of the walkthru
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Keyword",
            "Description"
    }

    
    process {
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('IseWalkthru')
        $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force 
            }
                    
        $found = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellWalkthru' and RowKey eq '$RowKey'" |
            Where-Object {
                $_.PartitionKey -eq 'PowerShellWalkthru'
            }
            
        if ($found) {
            if ($found.UserId -and ($toInput.UserId -ne $found.UserId)) {
                Write-Error 'Item does not belong to you'
                return            
            }
            $row = $found.rowKey
            $null = $toInput.psObject.Properties.Remove('Merge')
            $null = $toInput.psObject.Properties.Remove('RowKey')
            
            $toInput | 
                Update-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellWalkthru' -RowKey $rowKey -Value { $_ } -Merge:$merge -PassThru
        }
    }            
            
    
    
}

Set-Alias Set-PowerShellWalkthru Update-PowerShellWalkthru

try { 
    Export-ModuleMember -Function Update-PowerShellWalkthru -Alias Set-PowerShellWalkthru -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Remove-PowerShellWalkthru 
{    
    <#
    .Synopsis
        Removes items from IsePack PowerShellWalkthru
    .Description
        Updates PowerShellWalkthrus
    .Example
        Get-PowerShellWalkthru -ExactName 'A Specific Item' | 
            Remove-PowerShellWalkthru 
    .Link
        Remove-AzureTable
    #>        
    [CmdletBinding(DefaultParameterSetName='RowKey',SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    [string]
    $Keyword,
    
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    [string]
    $ExactName,
    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey        
    )
    
    process {                        
        $getParams = @{} + $psBoundParameters
        $getParams.Remove('WhatIf')
        $getParams.Remove('Confirm')
        if (-not $psBoundParameters.confirm -or ($psBoundParameters.Confirm -eq $false)) {
            if (-not $psBoundParameters.whatIf) {
                $confirmImpact = 'None'
            }
        }
        Get-PowerShellWalkthru @getParams |
            Where-Object {
                $item = $_
                $toInput = New-Object PSObject
                
                
                if (-not $item.UserId) { return $true } 
                if ($item.UserId -eq $toInput.UserId) {
                    return $true
                }                
            } | 
            Remove-AzureTable 
    }
}

Set-Alias Delete-PowerShellWalkthru Remove-PowerShellWalkthru

try { 
    Export-ModuleMember -Function Remove-PowerShellWalkthru -Alias Delete-PowerShellWalkthru -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}

function Add-PowerShellLink {
    <#
    .Synopsis
        Adds items to IsePack PowerShellLink
    .Description
        Adds PowerShellLinks 
    .Example
        Add-PowerShellLink
    .Link
        Set-AzureTable
    #>
    param(
    
    <#     
    The name of the link
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    The link
                 
    #>
    [Parameter(Mandatory=$true, Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Url,
    <#     
    A description of the link
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The author of the link
                 
    #>
    [Parameter(Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Author,
    <#     
    An image to use for the link
                 
    #>
    [Parameter(Position=5, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Image
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Url",
            "Description",
            "Author",
            "Image"
    }

    
    process {
        foreach ($v in 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer') {
            $null = $psBoundParameters.Remove($v)
        }
        $UserPartition = $partition
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('http://schema.org/Article')
        $bigItems = $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force -PassThru
            }
        
        $found = & { $false} 
            
        if (-not $found) {
            $table = 'IsePack'
            $partition = 'PowerShellLink'
            $rowKey = . { "{0:x}" -f (Get-Random) }
            $toInput | 
                Set-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellLink' -RowKey $rowKey -PassThru
        }
    }            
            
    
    
}

Set-Alias New-PowerShellLink Add-PowerShellLink
Set-Alias Create-PowerShellLink Add-PowerShellLink

try { 
    Export-ModuleMember -Function Add-PowerShellLink -Alias New-PowerShellLink,Create-PowerShellLink -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Get-PowerShellLink {
    <#
    .Synopsis
        Gets http://schema.org/Article items from IsePack PowerShellLink
    .Description
        Gets PowerShellLinks
    .Example
        Get-PowerShellLink
    .Example
        Get-PowerShellLink 'search term'
    .Example
        Get-PowerShellLink -ExactName 'exact name'
    .Example
        Get-PowerShellLink -ExactName 'exact name'
    .Link
        Get-AzureTable
    .Link
        Search-AzureTable
    .Link
        Write-Crud
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
    # The keyword to find within the items
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    
    [string]
    $Keyword,

    # The properties to return back from each item
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]    
    [string[]]
    $Select,
    
    # Find an item with this exact name
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    
    [string]
    $ExactName,
    
    # Find an item in this exact row
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [Parameter(Mandatory=$true,ParameterSetName='All',ValueFromPipelineByPropertyName=$true)]
    [switch]
    $All,
    
    
    
    
    
    
    
    # If set, will exclude table information
    [switch]    
    $ExcludeTableInfo    
    )
    
    begin {
        $unpackIt = {
            $DoNotConvertMarkdown = $false;
                    
            $item = $_
            $item.psobject.properties |                         
                Where-Object { 
                    $_.Value -and
                    ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                    (-not $_.Value.ToString().Contains(' ')) 
                }|                        
                ForEach-Object {
                    try {
                        $expanded = Expand-Data -CompressedData $_.Value
                        $item | Add-Member NoteProperty $_.Name $expanded -Force
                    } catch{
                        Write-Verbose $_
                    
                    }
                }
                
            if (-not $DoNotConvertMarkdown) {                 
                $item.psobject.properties |                         
                    Where-Object { 
                        ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                        (-not $_.Value.ToString().Contains('<')) 
                    }|                                   
                    ForEach-Object {
                        try {
                            $fromMarkdown = ConvertFrom-Markdown -Markdown $_.Value
                            $item | Add-Member NoteProperty $_.Name $fromMarkdown -Force
                        } catch{
                            Write-Verbose $_
                        
                        }
                    }
            }
            $item     
            
        
        }
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        
    }
    
    process {
        $selectIt = @{
            ExcludeTableInfo=$ExcludeTableInfo
            StorageAccount = $storageAccount
            StorageKey=  $storageKey
        }
        if ($select) {
            $selectIt['Select'] = $select
        }
        if ($psCmdlet.ParameterSetName -eq 'All') {
            
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellLink' } @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'Keyword') {
            if ($keyword.Trim() -eq '*') {
                throw "Keyword $keyword is too broad"
                return
            }

            if (-not $select) {
                $select = 'Name', 'Description', 'RowKey', 'PartitionKey'
            } else {
                $select += 'RowKey', 'PartitionKey'
                $select = $select | Select-Object -Unique
            }
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellLink' } -Select $select| 
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                } |
                Get-AzureTable -TableName 'IsePack' |
                 
                ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ExactName') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and Name eq '$ExactName'" @selectIt|
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'RowKey') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and RowKey eq '$RowKey'" @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ByUserID')  {            
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and UserID eq '$UserID'" @selectIt |
             
            ForEach-Object $unpackIt            
        }  elseif ($psCmdlet.ParameterSetName -eq 'ReadCode')  {            
            $readCodeFound = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq '' and ReadCode eq '$ReadCode'"
            $allReadings = foreach ($rcF in $readCodeFound) {
                if (-not $rcf) {continue }
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and  eq '$($rcf.RowKey)'"
            }
            $allReadings |                
                 
                ForEach-Object $unpackIt            
        } elseif ($psCmdlet.ParameterSetName -eq 'MyItem')  {
            if ($session -and $session['User'].UserID) {
                if (-not $keyword) { $keyword = '*' } 
                if ($exactName) { $keyword = $exactName } 

                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and UserID eq '$($session['User'].UserID)'" @selectIt |
                 
                ForEach-Object $unpackIt |
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                }
            } elseif ($env:UserName) {
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and UserID eq '$($env:UserName)'" @selectIt |
                 
                ForEach-Object $unpackIt
            }                        
        }
    }
}

Set-Alias Read-PowerShellLink Get-PowerShellLink
Set-Alias Search-PowerShellLink Get-PowerShellLink

try { 
    Export-ModuleMember -Function Get-PowerShellLink -Alias Read-PowerShellLink,Search-PowerShellLink -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Update-PowerShellLink {
    <#
    .Synopsis
        Updates items in IsePack PowerShellLink
    .Description
        Updates PowerShellLinks  
    .Example
        Get-PowerShellLink -ExactName 'A Specific Item' | 
            Update-PowerShellLink -Description 'A New Description'
    .Link
        Update-AzureTable
    #>
    param(    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [switch]
    $Merge,
    
    
    <#     
    The name of the link
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    The link
                 
    #>
    [Parameter(Mandatory=$true, Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Url,
    <#     
    A description of the link
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The author of the link
                 
    #>
    [Parameter(Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Author,
    <#     
    An image to use for the link
                 
    #>
    [Parameter(Position=5, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Image
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Url",
            "Description",
            "Author",
            "Image"
    }

    
    process {
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('http://schema.org/Article')
        $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force 
            }
                    
        $found = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellLink' and RowKey eq '$RowKey'" |
            Where-Object {
                $_.PartitionKey -eq 'PowerShellLink'
            }
            
        if ($found) {
            if ($found.UserId -and ($toInput.UserId -ne $found.UserId)) {
                Write-Error 'Item does not belong to you'
                return            
            }
            $row = $found.rowKey
            $null = $toInput.psObject.Properties.Remove('Merge')
            $null = $toInput.psObject.Properties.Remove('RowKey')
            
            $toInput | 
                Update-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellLink' -RowKey $rowKey -Value { $_ } -Merge:$merge -PassThru
        }
    }            
            
    
    
}

Set-Alias Set-PowerShellLink Update-PowerShellLink

try { 
    Export-ModuleMember -Function Update-PowerShellLink -Alias Set-PowerShellLink -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Remove-PowerShellLink 
{    
    <#
    .Synopsis
        Removes items from IsePack PowerShellLink
    .Description
        Updates PowerShellLinks
    .Example
        Get-PowerShellLink -ExactName 'A Specific Item' | 
            Remove-PowerShellLink 
    .Link
        Remove-AzureTable
    #>        
    [CmdletBinding(DefaultParameterSetName='RowKey',SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    [string]
    $Keyword,
    
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    [string]
    $ExactName,
    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey        
    )
    
    process {                        
        $getParams = @{} + $psBoundParameters
        $getParams.Remove('WhatIf')
        $getParams.Remove('Confirm')
        if (-not $psBoundParameters.confirm -or ($psBoundParameters.Confirm -eq $false)) {
            if (-not $psBoundParameters.whatIf) {
                $confirmImpact = 'None'
            }
        }
        Get-PowerShellLink @getParams |
            Where-Object {
                $item = $_
                $toInput = New-Object PSObject
                
                
                if (-not $item.UserId) { return $true } 
                if ($item.UserId -eq $toInput.UserId) {
                    return $true
                }                
            } | 
            Remove-AzureTable 
    }
}

Set-Alias Delete-PowerShellLink Remove-PowerShellLink

try { 
    Export-ModuleMember -Function Remove-PowerShellLink -Alias Delete-PowerShellLink -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}


$storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
    (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
} elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
    (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
}

$storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
    (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
} elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
    (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
}


# Connect to Azure Table Storage
$null = Get-AzureTable -TableName 'IsePack' -StorageAccount $storageAccount -StorageKey $storageKey
function Add-PowerShellVideo {
    <#
    .Synopsis
        Adds items to IsePack PowerShellVideo
    .Description
        Adds PowerShellVideos 
    .Example
        Add-PowerShellVideo
    .Link
        Set-AzureTable
    #>
    param(
    
    <#     
    The name of the video
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    A link to the video
                 
    #>
    [Parameter(Mandatory=$true, Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Url,
    <#     
    A description of the video
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The author of the video
                 
    #>
    [Parameter(Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Author,
    <#     
    An image to use for the video
                 
    #>
    [Parameter(Position=5, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Image
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Url",
            "Description",
            "Author",
            "Image"
    }

    
    process {
        foreach ($v in 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer') {
            $null = $psBoundParameters.Remove($v)
        }
        $UserPartition = $partition
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('http://schema.org/VideoObject')
        $bigItems = $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force -PassThru
            }
        
        $found = & { $false} 
            
        if (-not $found) {
            $table = 'IsePack'
            $partition = 'PowerShellVideo'
            $rowKey = . { "{0:x}" -f (Get-Random) }
            $toInput | 
                Set-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellVideo' -RowKey $rowKey -PassThru
        }
    }            
            
    
    
}

Set-Alias New-PowerShellVideo Add-PowerShellVideo
Set-Alias Create-PowerShellVideo Add-PowerShellVideo

try { 
    Export-ModuleMember -Function Add-PowerShellVideo -Alias New-PowerShellVideo,Create-PowerShellVideo -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Get-PowerShellVideo {
    <#
    .Synopsis
        Gets http://schema.org/VideoObject items from IsePack PowerShellVideo
    .Description
        Gets PowerShellVideos
    .Example
        Get-PowerShellVideo
    .Example
        Get-PowerShellVideo 'search term'
    .Example
        Get-PowerShellVideo -ExactName 'exact name'
    .Example
        Get-PowerShellVideo -ExactName 'exact name'
    .Link
        Get-AzureTable
    .Link
        Search-AzureTable
    .Link
        Write-Crud
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
    # The keyword to find within the items
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    
    [string]
    $Keyword,

    # The properties to return back from each item
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]    
    [string[]]
    $Select,
    
    # Find an item with this exact name
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    
    [string]
    $ExactName,
    
    # Find an item in this exact row
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [Parameter(Mandatory=$true,ParameterSetName='All',ValueFromPipelineByPropertyName=$true)]
    [switch]
    $All,
    
    
    
    
    
    
    
    # If set, will exclude table information
    [switch]    
    $ExcludeTableInfo    
    )
    
    begin {
        $unpackIt = {
            $DoNotConvertMarkdown = $false;
                    
            $item = $_
            $item.psobject.properties |                         
                Where-Object { 
                    $_.Value -and
                    ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                    (-not $_.Value.ToString().Contains(' ')) 
                }|                        
                ForEach-Object {
                    try {
                        $expanded = Expand-Data -CompressedData $_.Value
                        $item | Add-Member NoteProperty $_.Name $expanded -Force
                    } catch{
                        Write-Verbose $_
                    
                    }
                }
                
            if (-not $DoNotConvertMarkdown) {                 
                $item.psobject.properties |                         
                    Where-Object { 
                        ('Timestamp', 'RowKey', 'TableName', 'PartitionKey' -notcontains $_.Name) -and
                        (-not $_.Value.ToString().Contains('<')) 
                    }|                                   
                    ForEach-Object {
                        try {
                            $fromMarkdown = ConvertFrom-Markdown -Markdown $_.Value
                            $item | Add-Member NoteProperty $_.Name $fromMarkdown -Force
                        } catch{
                            Write-Verbose $_
                        
                        }
                    }
            }
            $item     
            
        
        }
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        
    }
    
    process {
        $selectIt = @{
            ExcludeTableInfo=$ExcludeTableInfo
            StorageAccount = $storageAccount
            StorageKey=  $storageKey
        }
        if ($select) {
            $selectIt['Select'] = $select
        }
        if ($psCmdlet.ParameterSetName -eq 'All') {
            
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellVideo' } @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'Keyword') {
            if ($keyword.Trim() -eq '*') {
                throw "Keyword $keyword is too broad"
                return
            }

            if (-not $select) {
                $select = 'Name', 'Description', 'RowKey', 'PartitionKey'
            } else {
                $select += 'RowKey', 'PartitionKey'
                $select = $select | Select-Object -Unique
            }
            Search-AzureTable -TableName 'IsePack' -Where { $_.PartitionKey -eq 'PowerShellVideo' } -Select $select| 
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                } |
                Get-AzureTable -TableName 'IsePack' |
                 
                ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ExactName') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and Name eq '$ExactName'" @selectIt|
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'RowKey') {
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and RowKey eq '$RowKey'" @selectIt |
             
            ForEach-Object $unpackIt
        } elseif ($psCmdlet.ParameterSetName -eq 'ByUserID')  {            
            Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and UserID eq '$UserID'" @selectIt |
             
            ForEach-Object $unpackIt            
        }  elseif ($psCmdlet.ParameterSetName -eq 'ReadCode')  {            
            $readCodeFound = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq '' and ReadCode eq '$ReadCode'"
            $allReadings = foreach ($rcF in $readCodeFound) {
                if (-not $rcf) {continue }
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and  eq '$($rcf.RowKey)'"
            }
            $allReadings |                
                 
                ForEach-Object $unpackIt            
        } elseif ($psCmdlet.ParameterSetName -eq 'MyItem')  {
            if ($session -and $session['User'].UserID) {
                if (-not $keyword) { $keyword = '*' } 
                if ($exactName) { $keyword = $exactName } 

                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and UserID eq '$($session['User'].UserID)'" @selectIt |
                 
                ForEach-Object $unpackIt |
                Where-Object {
                    $_.Name -ilike "*$keyword*" -or
                    $_.Description -ilike "*$keyword*"
                }
            } elseif ($env:UserName) {
                Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and UserID eq '$($env:UserName)'" @selectIt |
                 
                ForEach-Object $unpackIt
            }                        
        }
    }
}

Set-Alias Read-PowerShellVideo Get-PowerShellVideo
Set-Alias Search-PowerShellVideo Get-PowerShellVideo

try { 
    Export-ModuleMember -Function Get-PowerShellVideo -Alias Read-PowerShellVideo,Search-PowerShellVideo -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Update-PowerShellVideo {
    <#
    .Synopsis
        Updates items in IsePack PowerShellVideo
    .Description
        Updates PowerShellVideos  
    .Example
        Get-PowerShellVideo -ExactName 'A Specific Item' | 
            Update-PowerShellVideo -Description 'A New Description'
    .Link
        Update-AzureTable
    #>
    param(    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey,
    
    [switch]
    $Merge,
    
    
    <#     
    The name of the video
                 
    #>
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    <#     
    A link to the video
                 
    #>
    [Parameter(Mandatory=$true, Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Url,
    <#     
    A description of the video
    |LinesForInput 10             
    #>
    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Description,
    <#     
    The author of the video
                 
    #>
    [Parameter(Position=4, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Author,
    <#     
    An image to use for the video
                 
    #>
    [Parameter(Position=5, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Image
    )
    
    begin {
        $storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
        }

        $storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
            (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
        } elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
            (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
        }
        $schemaFields += "Name",
            "Url",
            "Description",
            "Author",
            "Image"
    }

    
    process {
        $toInput = New-Object PSObject -Property $psBoundParameters
        
        $toInput.psTypenames.clear()
        $toInput.psTypenames.add('http://schema.org/VideoObject')
        $psBoundParameters.GetEnumerator() |
            Where-Object { 
                $_.Value.Length -gt 2kb
            } |
            ForEach-Object {
                $toInput | Add-Member NoteProperty $_.Key (Compress-Data -String $_.Value) -Force 
            }
                    
        $found = Search-AzureTable -TableName 'IsePack' -Filter "PartitionKey eq 'PowerShellVideo' and RowKey eq '$RowKey'" |
            Where-Object {
                $_.PartitionKey -eq 'PowerShellVideo'
            }
            
        if ($found) {
            if ($found.UserId -and ($toInput.UserId -ne $found.UserId)) {
                Write-Error 'Item does not belong to you'
                return            
            }
            $row = $found.rowKey
            $null = $toInput.psObject.Properties.Remove('Merge')
            $null = $toInput.psObject.Properties.Remove('RowKey')
            
            $toInput | 
                Update-AzureTable -TableName 'IsePack' -PartitionKey 'PowerShellVideo' -RowKey $rowKey -Value { $_ } -Merge:$merge -PassThru
        }
    }            
            
    
    
}

Set-Alias Set-PowerShellVideo Update-PowerShellVideo

try { 
    Export-ModuleMember -Function Update-PowerShellVideo -Alias Set-PowerShellVideo -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}
function Remove-PowerShellVideo 
{    
    <#
    .Synopsis
        Removes items from IsePack PowerShellVideo
    .Description
        Updates PowerShellVideos
    .Example
        Get-PowerShellVideo -ExactName 'A Specific Item' | 
            Remove-PowerShellVideo 
    .Link
        Remove-AzureTable
    #>        
    [CmdletBinding(DefaultParameterSetName='RowKey',SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Keyword')]
    [string]
    $Keyword,
    
    [Parameter(Mandatory=$true,ParameterSetName='ExactName')]
    [string]
    $ExactName,
    
    [Parameter(Mandatory=$true,ParameterSetName='RowKey',ValueFromPipelineByPropertyName=$true)]
    [string]
    $RowKey        
    )
    
    process {                        
        $getParams = @{} + $psBoundParameters
        $getParams.Remove('WhatIf')
        $getParams.Remove('Confirm')
        if (-not $psBoundParameters.confirm -or ($psBoundParameters.Confirm -eq $false)) {
            if (-not $psBoundParameters.whatIf) {
                $confirmImpact = 'None'
            }
        }
        Get-PowerShellVideo @getParams |
            Where-Object {
                $item = $_
                $toInput = New-Object PSObject
                
                
                if (-not $item.UserId) { return $true } 
                if ($item.UserId -eq $toInput.UserId) {
                    return $true
                }                
            } | 
            Remove-AzureTable 
    }
}

Set-Alias Delete-PowerShellVideo Remove-PowerShellVideo

try { 
    Export-ModuleMember -Function Remove-PowerShellVideo -Alias Delete-PowerShellVideo -ErrorAction SilentlyContinue
} catch {
    Write-Debug 'Not in a module'
}


$storageAccount = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')) {
    (Get-WebConfigurationSetting -Setting 'AzureStorageAccountName')
} elseif ((Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)) {
    (Get-SecureSetting -Name 'AzureStorageAccountName' -ValueOnly)
}

$storageKey = if ((Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')) {
    (Get-WebConfigurationSetting -Setting 'AzureStorageAccountKey')
} elseif ((Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)) {
    (Get-SecureSetting -Name 'AzureStorageAccountKey' -ValueOnly)
}


# Connect to Azure Table Storage
$null = Get-AzureTable -TableName 'IsePack' -StorageAccount $storageAccount -StorageKey $storageKey


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUl+vZ9Rj8fbyW+oG3P/GnNJWe
# +zqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPZ4Akpa4x9xZLOy
# g3CmfdBr2LsVMA0GCSqGSIb3DQEBAQUABIIBAH/8dDsvEmJLU3p8TKy4nPKjvKju
# uM2eRMDQ/mGMSbkve8cXroYGJ5awO+xYyTgFEH+g/xLdSpVZKQmRernUMmx+tdEd
# iSd9UeC4LnZmYZCVLpkpCtIQwlPwmsno6K/DAVP9GJkidoZq543Y7CFNdTsx/717
# ymEZ/igJW0KONVU1q7txUI8FDWIQ2uOQyMc2mQt/7XmlsKOr9kqeXFCYcQz4sf1M
# lWCvkC3XItAXyjqV4xt1P6ikC45816du4Lx+upVCHyPCtnWsP+qJAOQwPQoiIeHJ
# IJ03qj7dUudeBbAmOvXCwKkuxmXD0sRTPb9F57ngMosY38BgEUOck7CNgeo=
# SIG # End signature block
