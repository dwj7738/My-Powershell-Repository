param($computer="localhost", $group, $help)

 

function funHelp()

{

$helpText=@"

DESCRIPTION:

NAME: CreateLocalGroup.ps1

Creates a local group on either a local or remote machine.

 

PARAMETERS:

-computer Specifies the name of the computer upon which to run the script

-group    Name of group to create

-help     prints help file

 

SYNTAX:

CreateLocalGroup.ps1

Generates an error. You must supply a group name

 

CreateLocalGroup.ps1 -computer MunichServer -group MyGroup

 

Creates a local group called MyGroup on a computer named MunichServer

 

CreateLocalGroup.ps1 -group Mygroup

 

Creates a local group called MyGroup on local computer

 

CreateLocalGroup.ps1 -help ?

 

Displays the help topic for the script

 

"@

$helpText

exit

}

 

if($help){ "Obtaining help ..." ; funhelp }

 

if(!$group)

      {

       $(Throw 'A value for $group is required.

       Try this: CreateLocalGroup.ps1 -help ?')

        }

     

$objOu = [ADSI]"WinNT://$computer"

$objUser = $objOU.Create("Group", $group)

$objUser.SetInfo()

$objUser.description = "Test Group"

$objUser.SetInfo()