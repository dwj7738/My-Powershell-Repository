##############################################################################
##
## Add-FormatTableIndexParameter
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Adds a new -IncludeIndex switch parameter to the Format-Table command
to help with array indexing.

.NOTES

This commands builds on New-CommandWrapper, also included in the Windows
PowerShell Cookbook.

.EXAMPLE

PS >$items = dir
PS >$items | Format-Table -IncludeIndex
PS >$items[4]

#>

Set-StrictMode -Version Latest

New-CommandWrapper Format-Table `
    -AddParameter @{
        @{
            Name = 'IncludeIndex';
            Attributes = "[Switch]"
        } = {

        function Add-IndexParameter {
            begin
            {
                $psIndex = 0
            }
            process
            {
                ## If this is the Format-Table header
                if($_.GetType().FullName -eq `
                    "Microsoft.PowerShell.Commands.Internal." +
                    "Format.FormatStartData")
                {
                    ## Take the first column and create a copy of it
                    $formatStartType =
                        $_.shapeInfo.tableColumnInfoList[0].GetType()
                    $clone =
                        $formatStartType.GetConstructors()[0].Invoke($null)

                    ## Add a PSIndex property
                    $clone.PropertyName = "PSIndex"
                    $clone.Width = $clone.PropertyName.Length

                    ## And add its information to the header information
                    $_.shapeInfo.tableColumnInfoList.Insert(0, $clone)
                }

                ## If this is a Format-Table entry
                if($_.GetType().FullName -eq `
                    "Microsoft.PowerShell.Commands.Internal." +
                    "Format.FormatEntryData")
                {
                    ## Take the first property and create a copy of it
                    $firstField =
                        $_.formatEntryInfo.formatPropertyFieldList[0]
                    $formatFieldType = $firstField.GetType()
                    $clone =
                        $formatFieldType.GetConstructors()[0].Invoke($null)

                    ## Set the PSIndex property value
                    $clone.PropertyValue = $psIndex
                    $psIndex++

                    ## And add its information to the entry information
                    $_.formatEntryInfo.formatPropertyFieldList.Insert(
                        0, $clone)
                }

                $_
            }
        }

        $newPipeline = { __ORIGINAL_COMMAND__ | Add-IndexParameter }
    }
}
