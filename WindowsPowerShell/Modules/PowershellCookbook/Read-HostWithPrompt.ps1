#############################################################################
##
## Read-HostWithPrompt
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Read user input, with choices restricted to the list of options you
provide.

.EXAMPLE

PS >$caption = "Please specify a task"
PS >$message = "Specify a task to run"
PS >$option = "&Clean Temporary Files","&Defragment Hard Drive"
PS >$helptext = "Clean the temporary files from the computer",
>>              "Run the defragment task"
>>
PS >$default = 1
PS >Read-HostWithPrompt $caption $message $option $helptext $default

Please specify a task
Specify a task to run
[C] Clean Temporary Files  [D] Defragment Hard Drive  [?] Help
(default is "D"):?
C - Clean the temporary files from the computer
D - Run the defragment task
[C] Clean Temporary Files  [D] Defragment Hard Drive  [?] Help
(default is "D"):C
0

#>

param(
    ## The caption for the prompt
    $Caption = $null,

    ## The message to display in the prompt
    $Message = $null,

    ## Options to provide in the prompt
    [Parameter(Mandatory = $true)]
    $Pption,

    ## Any help text to provide
    $HelpText = $null,

    ## The default choice
    $Default = 0
)

Set-StrictMode -Version Latest

## Create the list of choices
$choices = New-GenericObject `
    Collections.ObjectModel.Collection `
    Management.Automation.Host.ChoiceDescription

## Go through each of the options, and add them to the choice collection
for($counter = 0; $counter -lt $option.Length; $counter++)
{
    $choice = New-Object Management.Automation.Host.ChoiceDescription `
        $option[$counter]

    if($helpText -and $helpText[$counter])
    {
        $choice.HelpMessage = $helpText[$counter]
    }

    $choices.Add($choice)
}

## Prompt for the choice, returning the item the user selected
$host.UI.PromptForChoice($caption, $message, $choices, $default)
