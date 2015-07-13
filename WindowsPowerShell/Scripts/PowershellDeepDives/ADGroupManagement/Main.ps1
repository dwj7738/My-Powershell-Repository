################################################################
<#
Function: Search-LDAP 
Purpose: Search for a list of users or groups in Active Directory
#>
################################################################

function Search-Directory {

param
(
$objBindDN,
[string]$strLDAPFilter,
[string[]]$arrProps
)

$objSearch = New-Object DirectoryServices.DirectorySearcher
$objSearch.SearchRoot = $objBindDN
$objSearch.PageSize = 1000
$arrProps | ForEach-Object{$objSearch.PropertiesToLoad.Add($_)}
$objSearch.Filter = $strLDAPFilter

    try 
    {
    $objSearch.FindAll()
    }

    catch 
    {
    throw $_
    return
    }
}

################################################################
<#
Function: ConvertTo-ObjectArray
Purpose: Converts SearchResultCollection to PSObject array
#>
################################################################

function ConvertTo-ObjectArray {

param($coll,$prefix)

$lst = @()
$sam = $prefix + "SamAccountname"
$guid = $prefix + "Guid"
           
$coll | 
ForEach-Object {
    if ($_.properties.objectguid -ne $null) 
    {
        $obj = New-Object psobject `
        -Property @{$sam=[string]$_.properties.samaccountname; `
                    $guid=[guid]$_.properties.objectguid.item(0)}

        $lst += $obj
    }
}
$lst
}

################################################################
<#
Function: Add-PSScriptRoot
Purpose: finds the current directory where the script was executed
#>
################################################################

function Get-PSScriptRoot ($file)
{
$caller = Get-Variable -Value -Scope 1 MyInvocation
$caller.MyCommand.Definition |
Split-Path -Parent |
Join-Path -Resolve -ChildPath $file
}

################################################################
<#
Function: Get-UserData
Purpose: 
#>
################################################################

function Get-UserData {

$strConnection = "Data Source=$script:SQLServer; Initial Catalog=$script:DBName; Integrated Security=SSPI" 
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($strConnection) 

$strSQL = @"
SELECT dbo.UserTable.UserSamAccountname, dbo.UserTable.UserGUID 
FROM UserTable
"@

$sqlCommand = New-Object System.Data.SqlClient.sqlCommand
$sqlCommand.CommandText = $strSQL

$sqlDataSet = new-object System.Data.DataSet
$sqlDataAdapter = new-object System.Data.SqlClient.SqlDataAdapter
$sqlDataAdapter.selectCommand = $sqlCommand

    try 
    {
    $sqlConnection.open()
    $sqlCommand.Connection = $sqlConnection

    [void]$sqlDataAdapter.Fill($sqlDataSet,"LocalData")

    $sqlConnection.Close()
    $sqlCommand.Dispose()
    return $sqlDataSet.Tables[0]
    }

    catch 
    {
    write-host $_.exception
    $sqlConnection.Close()
    $sqlCommand.Dispose()
    }
} 


################################################################
<#
Function: Get-GroupData
Purpose: 
#>
################################################################

function Get-GroupData {

param 
(
$UserGUID
)

$strConnection = "Data Source=$script:SQLServer; Initial Catalog=$script:DBName; Integrated Security=SSPI" 
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($strConnection) 
$sqlConnection.open() 

$sqlCommand = New-Object System.Data.SqlClient.sqlCommand
$sqlCommand.Connection = $sqlConnection

$strSQL = @"
SELECT dbo.GroupTable.GroupSamAccountname, dbo.GroupTable.StartDate, dbo.GroupTable.EndDate,
dbo.GroupTable.GroupGUID, dbo.UserTable.UserGUID, dbo.UserTable.UserSamAccountname
FROM UserTable
INNER JOIN GroupTable
ON 
dbo.UserTable.UserGUID = dbo.GroupTable.UserGUID
WHERE 
dbo.UserTable.UserGUID = @UserGUID 
"@

$sqlCommand.CommandText = $strSQL

[void]$sqlCommand.Parameters.AddWithValue("@UserGUID", $UserGUID) 

$sqlDataSet = new-object System.Data.DataSet
$sqlDataAdapter = new-object System.Data.SqlClient.SqlDataAdapter
$sqlDataAdapter.selectCommand = $sqlCommand

    try 
    {
    [void]$sqlDataAdapter.Fill($sqlDataSet,"LocalData")
    $sqlConnection.Close()
    $sqlCommand.Dispose()
       
    $sqlDataSet.tables[0].DefaultView.AllowNew = $true
    $sqlDataSet.tables[0].PrimaryKey = $sqlDataSet.tables[0].Columns.Item("GroupGUID")

    return $sqlDataSet.tables[0]
    }

    catch 
    {
    write-host $_.exception
    $sqlConnection.Close()
    $sqlCommand.Dispose()
    }
}

################################################################
<#
Function: Set-GroupData
Purpose: 
#>
################################################################

function Set-GroupData {

begin 
{
$strConnection = "Data Source=$script:SQLServer; Initial Catalog=$script:DBName; Integrated Security=SSPI" 
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($strConnection) 
$sqlConnection.open() 
}

process 
{
$sqlCommand = New-Object System.Data.SqlClient.sqlCommand
$sqlCommand.Connection = $sqlConnection

$strSQL = @"
IF NOT EXISTS (SELECT * FROM UserTable WHERE UserGUID = @UserGUID)
    BEGIN 
        INSERT INTO UserTable (UserGUID, UserSamAccountName) 
        VALUES (@UserGUID, @UserSamAccountName) 
    END 

IF EXISTS (SELECT * FROM GroupTable WHERE GroupGUID = @GroupGUID AND UserGUID = @UserGUID)
    BEGIN 
        UPDATE GroupTable
        SET StartDate = @StartDate, EndDate = @EndDate 
        WHERE GroupGUID = @GroupGUID AND UserGUID = @UserGUID 
    END 
ELSE 
    BEGIN 
        INSERT INTO GroupTable (GroupGUID, GroupSamAccountName, UserGUID, StartDate, EndDate) 
        VALUES (@GroupGUID, @GroupSamAccountName, @UserGUID, @StartDate, @EndDate) 
    END
"@

$sqlCommand.CommandText = $strSQL

[void]$sqlCommand.Parameters.AddWithValue("@GroupGUID", $_.GroupGUID) 
[void]$sqlCommand.Parameters.AddWithValue("@GroupSamAccountName", $_.GroupSamAccountname) 
[void]$sqlCommand.Parameters.AddWithValue("@UserGUID", $_.UserGUID) 
[void]$sqlCommand.Parameters.AddWithValue("@UserSamAccountName", $_.UserSamAccountname) 
[void]$sqlCommand.Parameters.AddWithValue("@StartDate", $_.startDate) 
[void]$sqlCommand.Parameters.AddWithValue("@EndDate", $_.endDate) 

    try 
    {
    $sqlCommand.ExecuteNonQuery()
    }

    catch 
    {
    write-host $_.exception
    }

}


end 
{
$sqlConnection.Close()
$sqlCommand.Dispose()
}

}

################################################################
<#
Function: Get-TableSchema
Purpose: 
#>
################################################################

function Get-TableSchema {

$strConnection = "Data Source=$script:SQLServer; Initial Catalog=$script:DBName; Integrated Security=SSPI" 
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($strConnection) 
$sqlConnection.open() 

$strSQL = @"
SELECT TOP 0 dbo.GroupTable.GroupSamAccountname, dbo.GroupTable.GroupGUID, dbo.GroupTable.StartDate, 
dbo.GroupTable.EndDate, dbo.UserTable.UserSamAccountname, dbo.UserTable.UserGUID
FROM GroupTable,UserTable
"@

$sqlCommand = New-Object System.Data.SqlClient.sqlCommand($strSQL,$sqlConnection)
$dataTable = New-Object System.Data.DataTable
$sqlReader = $sqlCommand.ExecuteReader()
$dataTable = $sqlReader.GetSchemaTable()

$sqlConnection.Close()
$sqlCommand.Dispose()

return $dataTable
}


######################################################
# Main Code starts here
######################################################

# add references to the .NET WPF assemblies
Add-Type -Assembly PresentationCore,PresentationFrameWork,WindowsBase

# resolve the full path to the XAML file from the current script directory path
# get XAML markup file path
$strXAMLFilePath = Get-PSScriptRoot -file UI.xaml

# get XAML markup file contents
[xml]$xmlUI = Get-Content (Get-PSScriptRoot -file UI.xaml)

# load XAML markup to create the WPF form
$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader($xmlUI)) )

# set ADSI search root for LDAP queries
$dirEntry = [ADSI]""

# define SQL server & DB name at script scope
$script:SQLServer = "WIN8-01.corp.fabrikam.com"
$script:DBName = "ADGroupManagementDB"

#####################################################
# Get UI control references
#####################################################

# DataGrid
$grdUser = $window.FindName("grdUser")
$grdGroup = $window.FindName("grdGroup")

$grdSearchUser = $window.FindName("grdSearchUser")
$grdSearchGroup = $window.FindName("grdSearchGroup")

$grdSelectedUser = $window.FindName("grdSelectedUser")
$grdSelectedGroup = $window.FindName("grdSelectedGroup")

# Button
$btnSearchUser = $window.FindName("btnSearchUser")
$btnSearchGroup = $window.FindName("btnSearchGroup")
$btnSaveChanges = $window.FindName("btnSaveChanges")

# TextBox
$txtSearchUser = $window.FindName("txtSearchUser")
$txtSearchGroup = $window.FindName("txtSearchGroup")

# Label
$lblSelectedUserName = $window.FindName("lblSelectedUserName")

######################################################
# wire-up form control event handlers
######################################################

$btnSearchUser.Add_Click({

if ($txtSearchUser.Text -ne "") 
{
$strLDAPFilter = "(&(objectclass=user)(objectcategory=person)(samaccountname=$($txtSearchUser.Text)*))"  
$result = Search-Directory -objBindDN $dirEntry -strLDAPFilter $strLDAPFilter -arrProps "samaccountname","objectguid","distinguishedname"
                            
        if ($result.count -gt 0) 
        {
        $grdSearchUser.ItemsSource = @(ConvertTo-ObjectArray -coll $result -prefix "User")
        $lblSelectedUserName.Content = "None"

            if ($grdSelectedgroup.ItemsSource -ne $null) 
            {
            $grdSelectedgroup.ItemsSource.Table.Clear() 
            }
        }
    }
})

$btnSearchGroup.Add_Click({

if ($txtSearchGroup.Text -ne "") 
{
$strLDAPFilter = "(&(objectclass=group)(samaccountname=$($txtSearchGroup.Text)*))"
$result = Search-Directory -objBindDN $dirEntry -strLDAPFilter $strLDAPFilter -arrProps "samaccountname","objectguid","distinguishedname"
                                
            if ($result.count -gt 0) 
            {
            $grdSearchGroup.ItemsSource = @(ConvertTo-ObjectArray -coll $result -prefix "Group")
            }
        }
})

$grdSearchUser.Add_SelectionChanged({

if ($grdSearchUser.SelectedItem -ne $null) 
{     
$lblSelectedUserName.Content = $grdSearchUser.SelectedItem.UserSamAccountname
    
            if ($grdSelectedgroup.ItemsSource -ne $null) 
            {
            $grdSelectedgroup.ItemsSource.Table.Clear()
            }
    }
}) 

$grdSearchGroup.Add_SelectionChanged({ 

if ( ($grdSelectedgroup.ItemsSource -ne $null) )
{
    if (-not $grdSelectedgroup.ItemsSource.Table.Rows.Contains($grdSearchGroup.SelectedItem.GroupGUID)) 
    {
    $row = $grdSelectedgroup.ItemsSource.Table.NewRow()
    $row["GroupSamAccountname"] = $grdSearchGroup.SelectedItem.GroupSamAccountname
    $row["GroupGUID"] = $grdSearchGroup.SelectedItem.GroupGUID

        if ($grdSearchUser.ItemsSource -eq $null) 
        {
        $row["UserGUID"] = $grdUser.SelectedItem.UserGUID
        $row["UserSamAccountName"] = $grdUser.SelectedItem.UserSamAccountname
        }
        else
        {
        $row["UserGUID"] = $grdSearchUser.SelectedItem.UserGUID
        $row["UserSamAccountName"] = $grdSearchUser.SelectedItem.UserSamAccountname
        }

    $grdSelectedgroup.ItemsSource.Table.Rows.Add($row) 
    }
}

elseif (($grdSearchUser.SelectedItem -ne $null) -and ($grdSearchGroup.SelectedItem -ne $null))
{
       $SchemaTable = Get-TableSchema
       $Table = new-object System.Data.DataTable("Data")
        
       $SchemaTable | ForEach-Object {
       $column = new-object System.Data.DataColumn
       $column.ColumnName = $_.columnName
       $column.DataType = $_.DataType
       $Table.Columns.Add($column)  
       }

       $row = $Table.NewRow()

       $row["GroupSamAccountName"] = $grdSearchGroup.SelectedItem.GroupSamAccountname
       $row["GroupGUID"] = $grdSearchGroup.SelectedItem.GroupGUID
       $row["UserGUID"] = $grdSearchUser.SelectedItem.UserGUID
       $row["UserSamAccountName"] = $grdSearchUser.SelectedItem.UserSamAccountname

       $Table.Rows.Add($row)
       $Table.PrimaryKey = $Table.Columns.Item("GroupGUID")
       $grdSelectedgroup.DataContext = $Table.DefaultView              
}
else 
{}

})

$grdUser.Add_Loaded({

   $data = Get-UserData    
   if ($data) {       
   $grdUser.DataContext = $data
   }
})

$grdUser.Add_SelectionChanged({  
 
    if ($grdUser.Items.count -gt 0) 
    {  
    $grdSelectedGroup.DataContext = @(Get-GroupData -userGUID $grdUser.SelectedItem.UserGUID)
    $lblSelectedUserName.Content = $grdUser.SelectedItem.UserSamAccountname
    }
})

$btnSaveChanges.Add_Click({

$dateError = $false

# check that all rows have a valid start & end date specified
foreach ($row in $grdSelectedGroup.ItemsSource.Table.DefaultView.Table.Rows)  
{  
       if ((-not $row.IsNull("EndDate")) -and (-not $row.IsNull("StartDate")))
       {          
           if ([datetime]$row.EndDate -lt [datetime]$row.StartDate)
           {            
           $dateError = $true 
           }    
       } 
       else
       {
        $dateError = $true
       } 
}

   if ($dateError) 
   {
   $wsh = New-Object -ComObject wscript.shell
   $wsh.popup("Date is null or EndDate before StartDate",$null,"Error",0)
   }
   else
   {
   $changedRows = ($grdSelectedGroup.ItemsSource.Table.DefaultView.Table.GetChanges())

        if ($changedRows) 
        {
        $changedrows.Rows | Set-GroupData
        }
    }
})

# show the WPF form
$window.showdialog()


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbJ9WFYhKT3CgeFH36JT1NbJd
# P3CgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFB2K3tzTMcYV+AHE
# DcHdBcsR2lfJMA0GCSqGSIb3DQEBAQUABIIBAJKdbydtBRvKbkfW9l7CV9nnhcSW
# Y/Eu0i7fyf9A+qZZn/Hg6M/MTdN3UHiw38GsJeIqz0ocz3nnWxB70bLV4qmLBtSH
# a3R2HDSLba74liM94PwAvQ8dG6n0vYiA2da0B1VZ/9urgBmKFvsUAQA4fRhs4uCQ
# EW2kZvx9qEUVMdOWYhLYwDVp5682gbsU0CzmuuAgUoFXRlo156wEGgFwTEpm7i/u
# g5f1U/rtF2Fu4k6oh48atf9ZBY9is82Ta71R16A+P4t8vU6HroVmb+tJCvsLhwNQ
# TlPLTJxAbVgT4mFygC3QJz0m7eAwX+6/D9yrfpuV2aWXMvJzweGEOhL79bU=
# SIG # End signature block
