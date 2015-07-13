<# 
 .Synopsis
  Uses ADO .NET to query SQL

 .Description
  Queries a SQL Database and returns a datatable of results

 .Parameter query
  The SQL Query to run
 
 .Parameter parameters
  A list of SQLParameters to pass to the query

  .Parameter connectionString
   Sql Connection string for the DB to connect to

   .Parameter timeout
   timeout property for SQL query. Default is 60 seconds

 .Example
   # run a simple query

   $connectionString = ""
   $parameters = @{}
   Invoke-SqlQuery -query "SELECT GroupID, GroupName From [dbo].[Group] WHERE GroupName=@GroupName" -parameters @{"@GroupName"="genmills\groupName"} -connectionString $connectionString;
   Invoke-SqlQuery -query "SELECT GroupID, GroupName From [dbo].[Group]" -parameters @{} -connectionString $connectionString;
   
#>
function Invoke-SqlQuery([string]$query, [System.Collections.Hashtable] $parameters, [string] $connectionString, [int]$timeout=60)
{
    # convert parameter string to array of SqlParameters

    try
    {
        $sqlConnection = new-object System.Data.SqlClient.SqlConnection $connectionString
        $sqlConnection.Open()

        #Create a command object
        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $query;
        if($parameters)
        {
            foreach($key in $parameters.Keys)
            {
                $sqlCommand.Parameters.AddWithValue($key, $parameters[$key]) | Out-Null
            }
        }
		
		$sqlCommand.CommandTimeout = $timeout

        #Execute the Command
        $sqlReader = $sqlCommand.ExecuteReader()

        $Datatable = New-Object System.Data.DataTable
        $DataTable.Load($SqlReader)


        return $DataTable;
    }
    finally
    {
        if($sqlConnection -and $sqlConnection.State -ne [System.Data.ConnectionState]::Closed)
        {
            $sqlConnection.Close();
        }
    }
}
export-modulemember -Function *