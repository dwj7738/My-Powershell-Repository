****************************************
DSC Resource - xRemoteDesktopAdmin
Microsoft Corporation 2014
****************************************
Summary:
This resource provides a method of configuring remote desktop settings and configuring the Windows firewall by applying a configuration to your local or to a remote machine.
This is primarily intended for preventing that you cannot set up a remote desktop connection to a deployed machine where you don't have physical access to caused by a misconfiguration.
A good real life example is deploying a virtual machine to Microsoft Azure, based on a custom image, where remote settings have not been configured properly.

The two sample configuration files also show you how to add a domain user to the local "Remote Desktop Users" group utilizing the DSC Group resource, which ships in box.
Also demonstrated is how to use encrypted passwords in the MOF file (best practice) utilizing certificates, please refer to http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx for instructions how to use certificates to use encrypted passwords.
For test purposes, the sample also shows how to use passwords which are stored in clear text in the MOF file (not a best practice, for testing purposes only)

PreRequisites:
This module is dependent on the following DSC modules:
* xNetworking and the xFirewall resource
* Group (out of the box present, no need to install it)

Contents:
This module includes 1 DSC resource that automate the configuration of remote settings:
* xRemoteDesktopAdmin - DSC Module
* xRemoteDesktopAdmin.psm1 - DSC resource (PowerShell script module)
* xRemoteDesktopAdmin.schema.mof - DSC resource (schema file)
* xRemoteDesktopAdmin.psd1 - PowerShell datafile
* ExampleConfiguration-RemoteDesktopAdmin.ps1 - an example to generate a MOF file
* ExampleConfiguration-RemoteDesktopAdminWithEncryptedPassword.ps1 - an example for storing an encrypted password when using the DSC Group resource
* ExampleConfiguration-RemoteDesktopAdminWithUnEncryptedPassword.ps1 - an example for storing a password in clear text (for testing purposes only) when using the DSC Group resource

How-To:
To 'install' this resource on your machine -
* Copy the contents of this archive file in to:
	C:\Program Files\WindowsPowerShell\Modules\xRemoteDesktopAdmin
* Create a 'working directory' (C:\RDP\MOF has been set in the sample file) and execute the example configuration scripts to create a MOF file

How-To Test:
* Apply this configuration to a machine which has not been configured with remote desktop settings:
	- Navigate to "Remote Settings" (applies to Windows Server 2012 and above)
	- Under "Remote Desktop", select "Don't allow remote connections to this computer"

* The expected outcome (when configuration is set to "Ensure = Present") would be that under "Remote Settings -> Remote Desktop" the setting "Allow remote connections to this computer" is enabled
	- Optionally connections are allowed only for computers running "Network Level Authentication"

* If you are using the sample configuration, a domain user should be added to the local "Remote Desktop Users" group

* If configured, as in the sample configuration, a Windows firewall rule gets created (name: "DSC - Remote Desktop Admin Connections", DisplayGroup = "Remote Desktop") and will be set to "Enable = Yes"










