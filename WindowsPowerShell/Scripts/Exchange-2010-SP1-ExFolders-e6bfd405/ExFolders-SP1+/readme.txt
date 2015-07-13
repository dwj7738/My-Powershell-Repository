#################################################################################
# 
# The sample scripts are not supported under any Microsoft standard support 
# program or service. The sample scripts are provided AS IS without warranty 
# of any kind. Microsoft further disclaims all implied warranties including, without 
# limitation, any implied warranties of merchantability or of fitness for a particular 
# purpose. The entire risk arising out of the use or performance of the sample scripts 
# and documentation remains with you. In no event shall Microsoft, its authors, or 
# anyone else involved in the creation, production, or delivery of the scripts be liable 
# for any damages whatsoever (including, without limitation, damages for loss of business 
# profits, business interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages
#
#################################################################################

ExFolders Tool Readme

1. INSTALLATION:

- ExFolders must be run from an Exchange Server 2010 machine with the Microsoft Exchange Active Directory Topology service, which means it will not currently run on a tools-only install. This might change in the future.
- ExFolders.exe must be placed in the server's Exchange \bin folder. If you try to run it from anywhere else, it will simply crash.
- This build is not signed. In order to allow it to run, you can import the included .reg file on the server where you want to run the tool or run "sn -Vr ExFolders.exe" (using the 64 bit version of the SN tool) to allow it to launch. If you don't, it will crash. To read more about the SN tool, please go here: http://msdn.microsoft.com/en-us/library/k5b5tt23.aspx

2. VARIOUS TOOL NOTES:

- ExFolders can connect to stores on Exchange 2010 or 2007 only, both mailbox and public stores. Connection to Exchange 2003 and earlier is not possible (use PFDAVAdmin for that)
- ExFolders can now connect to more than one mailbox store at a time; just ctrl-click or shift-click to select multiple stores. This allows you to operate against multiple servers or every single mailbox in the org all at once if you need to do so.
- You'll notice the Tools menu now gives you the option to Export Item Properties, which allows you to export item properties to a tab-delimited file (just like the Export Folder Properties option). Item property imports are not implemented.
- Folder property imports are implemented. Tools -> Import, just like any other import. Note that the default property list in Export Folder Properties contains a lot of properties that are not writable, so if you turn around and try to import that same file, you will see a lot of errors. Any properties that are not writable (other than the Folder Path) should be removed from the file before importing.
- The old Property Editor has been changed to Bulk Property Editor, and a new Property Editor has been added, which is better-suited to editing properties on a single folder or item. Also note you can File -> Save to save the window contents to a file.
- The permissions interface, including the Folder Permissions GUI and exports/imports, supports the special Free/Busy rights on Calendar folders. Exports/Imports have two new keywords, FreeBusyDetails and FreeBusyBasic.
- The format of mailbox folder paths in imports/exports has changed, so mailbox exports from PFDAVAdmin cannot be imported with ExFolders, and vice-versa.
- Set Calendar Permissions will throw an error and not make any changes to a mailbox if it doesn't find the FreeBusy Data folder in the mailbox root, which means the user has never logged on to the mailbox. This is by design (because if we set rights on the Calendar folder and the FreeBusy Data folder later gets created, the permissions won't match).
- When you connect to mailboxes, some folders will appear in blue. These are search folders. They are ignored when you run Content Report.
- Set Calendar Permissions and Item Property Export are not currently exposed through Custom Bulk Operation.
