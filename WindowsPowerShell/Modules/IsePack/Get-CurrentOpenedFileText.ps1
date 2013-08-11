function Get-CurrentOpenedFileText {
    <#
    .Synopsis
        Gets the PowerShell Parser Tokens for the current file
    .Description
        Converts the current file into a list of powershell tokens
        Scripters can use these tokens to figure out exact context within a script
    .Example
        Get-CurrentOpenedFileToken 
    .Link
        Get-TokenFromFile
    #>
    param()
    Get-CurrentDocument -Text
}

