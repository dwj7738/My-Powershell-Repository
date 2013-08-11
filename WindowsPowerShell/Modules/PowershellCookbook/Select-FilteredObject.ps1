##############################################################################
##
## Select-FilteredObject
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Provides an inteactive window to help you select complex sets of objects.
To do this, it takes all the input from the pipeline, and presents it in a
notepad window.  Keep any lines that represent objects you want to retain,
delete the rest, then save the file and exit notepad.

The script then passes the original objects that you kept along the
pipeline.

.EXAMPLE

Get-Process | Select-FilteredObject | Stop-Process -WhatIf
Gets all of the processes running on the system, and displays them to you.
After you've selected the ones you want to stop, it pipes those into the
Stop-Process cmdlet.

#>

## PowerShell runs your "begin" script block before it passes you any of the
## items in the pipeline.
begin
{
    Set-StrictMode -Version Latest

    ## Create a temporary file
    $filename = [System.IO.Path]::GetTempFileName()

    ## Define a header in a "here-string" that explains how to interact with
    ## the file
    $header = @"
############################################################
## Keep any lines that represent obects you want to retain,
## and delete the rest.
##
## Once you finish selecting objects, save this file and
## exit.
############################################################

"@

    ## Place the instructions into the file
    $header > $filename

    ## Initialize the variables that will hold our list of objects, and
    ## a counter to help us keep track of the objects coming down the
    ## pipeline
    $objectList = @()
    $counter = 0
}

## PowerShell runs your "process" script block for each item it passes down
## the pipeline. In this block, the "$_" variable represents the current
## pipeline object
process
{
    ## Add a line to the file, using PowerShell's format (-f) operator.
    ## When provided the ouput of Get-Process, for example, these lines look
    ## like:
    ## 30: System.Diagnostics.Process (powershell)
    "{0}: {1}" -f $counter,$_.ToString() >> $filename

    ## Add the object to the list of objects, and increment our counter.
    $objectList += $_
    $counter++
}

## PowerShell runs your "end" script block once it completes passing all
## objects down the pipeline.
end
{
    ## Start notepad, then call the process's WaitForExit() method to
    ## pause the script until the user exits notepad.
    $process = Start-Process Notepad -Args $filename -PassThru
    $process.WaitForExit()

    ## Go over each line of the file
    foreach($line in (Get-Content $filename))
    {
        ## Check if the line is of the special format: numbers, followed by
        ## a colon, followed by extra text.
        if($line -match "^(\d+?):.*")
        {
            ## If it did match the format, then $matches[1] represents the
            ## number -- a counter into the list of objects we saved during
            ## the "process" section.
            ## So, we output that object from our list of saved objects.
            $objectList[$matches[1]]
        }
    }

    ## Finally, clean up the temporary file.
    Remove-Item $filename
}
