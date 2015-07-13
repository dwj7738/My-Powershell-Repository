@{
	# Script module or binary module file associated with this manifest
	ModuleToProcess = 'NTFSSecurity.psm1'

	# Version number of this module.
	ModuleVersion = '3.2.3'

	# ID used to uniquely identify this module
	GUID = 'cd303a6c-f405-4dcb-b1ce-fbc2c52264e9'

	# Author of this module
	Author = 'Raimund Andree'

	# Company or vendor of this module
	CompanyName = 'Raimund Andree'

	# Copyright statement for this module
	Copyright = '2014'

	# Description of the functionality provided by this module
	Description = 'Windows PowerShell Module for managing file and folder security on NTFS volumes'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '2.0'

	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''

	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''

	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '3.5'

	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = ''

	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture = ''

	# Modules that must be imported into the global environment prior to importing this module
	# for example 'ActiveDirectory'
	RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# for example 'System.Management.Configuration'
	RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module
	ScriptsToProcess = @('NTFSSecurity.Init.ps1')

	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess = @('NTFSSecurity.types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in ModuleToProcess
	NestedModules = @('NTFSSecurity.dll')

	# Functions to export from this module
	#FunctionsToExport = ''

	# Cmdlets to export from this module
	#CmdletsToExport = ''

	# Variables to export from this module
	#VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport = '*'

	# List of all modules packaged with this module
	ModuleList = @('NTFSSecurity.dll')

	# List of all files packaged with this module
	FileList = @('NTFSSecurity.dll', 'NTFSSecurity.types.ps1xml', 'NTFSSecurity.format.ps1xml', 'NTFSSecurity.Init.ps1', 'NTFSSecurity.psm1')

	# Private data to pass to the module specified in ModuleToProcess
	PrivateData = @{ 
		EnablePrivileges = $true
		GetInheritedFrom = $true
		GetFileSystemModeProperty = $false
		ShowAccountSid = $false
	}
}