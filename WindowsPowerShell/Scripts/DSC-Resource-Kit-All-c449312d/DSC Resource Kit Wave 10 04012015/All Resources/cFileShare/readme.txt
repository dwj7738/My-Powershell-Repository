**********************************************
cFileShare walkthrough
ALM Rangers 2014
**********************************************

Summary:
This walkthrough and the included samples show how to build a custom DSC Module which creates a folder, shares it and sets permissions on it (or removes it).

PreRequisites:
* A DSC Pull Server has been configured (see http://powershell.org/wp/2013/10/03/building-a-desired-state-configuration-pull-server/ for details)
* One or more targets for the DSC Pull Server have been configured (i.e. machines to listen for new configurations from the Pull server)
* PowerShell 4.0 is installed (available as part of the Windows Management Framework 4 which can be found here: http://www.microsoft.com/en-us/download/details.aspx?id=40855)
* The xDscResourceDesigner is installed. This can be found here: http://gallery.technet.microsoft.com/scriptcenter/xDscResourceDesigne-Module-22eddb29

Contents:
- ResourceDesignerScripts: Generate_cFileShare_Schema.ps1
  This file will create the basic outline as described in the walkthrough
- DSCResources: Contains the VSAR_cCreateFileShare and VSAR_cSetSharePermissions resources
- Unit Tests: Contains unit test files for each resource. Please note that the unit tests require that they be run as an administrator because they create the folder for the share in the root c drive. In addition, the users are specific to the test environment that I used (in the VSAR_cSetSharePermissions_UnitTests.ps1 file). They can be changed to any valid users (either local or domain)
- Examples: Contains the sample scripts described below

Sample scripts:
Note: In all samples, replace the target server name, folder path, share name and user values.
* CreateDropShare: This is the configuration file from the result of the walkthrough. It creates a folder, shares it and assigns permissions. 
* CreateMultipleShares: This sample creates multiple shares in a single configuration but does not assign any permissions to them.
* AlterPermissions: Removes permissions for two users from an existing share
