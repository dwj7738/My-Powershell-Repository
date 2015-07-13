Configuration CreateMultipleShares
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

        cCreateFileShare CreateSecondShare
        {
            ShareName = '[Share Name]'
            Path      = '[folder path]'
            Ensure    = 'Present'
        }
    }
}
CreateMultipleShares 
