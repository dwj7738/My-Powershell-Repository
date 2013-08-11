##############################################################################
##
## Add-ExtendedFileProperties
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Add the extended file properties normally shown in Exlorer's
"File Properties" tab.

.EXAMPLE

Get-ChildItem | Add-ExtendedFileProperties.ps1 | Format-Table Name,"Bit Rate"

#>

begin
{
    Set-StrictMode -Version Latest

    ## Create the Shell.Application COM object that provides this
    ## functionality
    $shellObject = New-Object -Com Shell.Application

    ## Store the property names and identifiers for all of the shell
    ## properties
    $itemProperties = $null
}

process
{
    ## Get the file from the input pipeline. If it is just a filename
    ## (rather than a real file,) piping it to the Get-Item cmdlet will
    ## get the file it represents.
    $fileItem = $_ | Get-Item

    ## Don't process directories
    if($fileItem.PsIsContainer)
    {
        $fileItem
        return
    }

    ## Extract the file name and directory name
    $directoryName = $fileItem.DirectoryName
    $filename = $fileItem.Name

    ## Create the folder object and shell item from the COM object
    $folderObject = $shellObject.NameSpace($directoryName)
    $item = $folderObject.ParseName($filename)

    ## Populate the item properties
    if(-not $itemProperties)
    {
        $itemProperties = @{}

        $counter = 0
        $columnName = ""
        do
        {
            $columnName = $folderObject.GetDetailsOf(
                $folderObject.Items, $counter)
            if($columnName) { $itemProperties[$counter] = $columnName }

            $counter++
        } while($columnName)
    }

    ## Now, go through each property and add its information as a
    ## property to the file we are about to return
    foreach($itemProperty in $itemProperties.Keys)
    {
        $fileItem | Add-Member NoteProperty $itemProperties[$itemProperty] `
            $folderObject.GetDetailsOf($item, $itemProperty) -ErrorAction `
            SilentlyContinue
    }

    ## Finally, return the file with the extra shell information
    $fileItem
}
