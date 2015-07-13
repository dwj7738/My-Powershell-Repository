Configuration AlterPermissions
{
    Import-DscResource -ModuleName cFileShare

    node [target server name]
    {
        cSetSharePermissions SetPermissions
        {
            ShareName         = '[Share name]'
            Ensure	          = 'Absent'
            FullAccessUsers   = @('[user 1]')
            ChangeAccessUsers = @('[user 2]')
        }
    }
}
AlterPermissions 
