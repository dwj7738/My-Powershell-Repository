Configuration CreateDropShare
{
    Import-DscResource -ModuleName cFileShare

    node [target server name]
    {
        cCreateFileShare CreateShare
        {
            ShareName = '[share name]'
            Path      = '[folder path]'
            Ensure    = 'Present'
        }

        cSetSharePermissions SetPermissions
        {
            ShareName         = '[share name]'
            DependsOn         = '[cCreateFileShare]CreateShare'
            Ensure	          = 'Present'
            FullAccessUsers   = @('[user1]')
            ChangeAccessUsers = @('[user2]')
            ReadAccessUsers   = @('[user3]')
        }
    }
}
CreateDropShare 
