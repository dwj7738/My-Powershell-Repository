function Remove-SQL
{
    <#
    .Synopsis
        Removes SQL data
    .Description
        Removes SQL data or databases
    .Example
        Remove-Sql -TableName ATable -ConnectionSetting SqlAzureConnectionString
    .Example
        Remove-Sql -TableName ATable -Where 'RowKey = 1' -ConnectionSetting SqlAzureConnectionString        
    .Example
        Remove-Sql -TableName ATable -Clear -ConnectionSetting SqlAzureConnectionString        
    .Link
        Add-SqlTable
    .Link
        Update-SQL
    #>
    [CmdletBinding(DefaultParameterSetName='DropTable',SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
    # The table containing SQL results
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('Table','From', 'Table_Name')]
    [string]$TableName,


    # The where clause.
    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='DeleteRows')]
    [string]$Where,

    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='ClearTable')]
    [Switch]$Clear,

    # A connection string or setting.
    [Parameter(Mandatory=$true)]
    [Alias('ConnectionString', 'ConnectionSetting')]
    [string]$ConnectionStringOrSetting

    )

    begin {
        if ($ConnectionStringOrSetting -notlike "*;*") {
            $ConnectionString = Get-SecureSetting -Name $ConnectionStringOrSetting -ValueOnly
        } else {
            $ConnectionString =  $ConnectionStringOrSetting
        }
        if (-not $ConnectionString) {
            throw "No Connection String"
            return
        }
        $sqlConnection = New-Object Data.SqlClient.SqlConnection "$connectionString"
        $sqlConnection.Open()
    }

    process {
        if ($TableName -and $where) {
            $sqlStatement = "DELETE FROM $tableName $(if ($Where) { "WHERE $where"})".TrimEnd("\").TrimEnd("/")
        } elseif ($clear) {
            $sqlStatement = "TRUNACATE TABLE $tableName"
        } else {
            

            $sqlStatement = "DROP TABLE $tableName"
        }

        if ($psCmdlet.ShouldProcess($sqlStatement)) {
        
        
            Write-Verbose "$sqlStatement"
            $sqlAdapter= New-Object "Data.SqlClient.SqlDataAdapter" ($sqlStatement, $sqlConnection)
            $sqlAdapter.SelectCommand.CommandTimeout = 0
            $dataSet = New-Object Data.DataSet
            $rowCount = $sqlAdapter.Fill($dataSet)

        
            foreach ($t in $dataSet.Tables) {
            
                foreach ($r in $t.Rows) {
                    $r.pstypenames.clear()
                    if ($r.pstypename) {                    
                        foreach ($tn in ($r.pstypename -split "\|")) {
                            $r.pstypenames.add($tn)
                        }
                    }
                
                    $r
                
                }
            }

        }
        
    }

    end {
         
        if ($sqlConnection) {
            $sqlConnection.Close()
            $sqlConnection.Dispose()
        }
        
    }
}
 
