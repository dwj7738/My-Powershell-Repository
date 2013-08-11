First file RotateBackups_MasterList.txt
RowNbr,BackupName,VersionsRetained,BackupType
1,TargetBackup,2,Folder
2,LstDefBackup,5,File
3,XMLBackup,3,File
4,SourceBackup,2,Folder
5,TXTBackup,8,File

Second file RotateBackups_FolderList.txt
RowNbr,BackupName,FolderName
1,TargetBackup,c:\MyBooks\target
2,SourceBackup,c:\MyBooks\source

Third file RotateBackups_FileExtensions.txt
RowNbr,BackupName,FileExtension,FolderLoc
1,LstDefBackup,*.def,c:\MyBooks\target
2,LstDefBackup,*.lst,c:\MyBooks\target
3,XMLBackup,*.xml,c:\MyBooks\target
4,TXTBackup,*.txt,c:\MyBooks\rfiles


When executed, files are created in c:\Zipfiles that have a name associated with the BackupName, a batch date-time. BackupName files are counted & compared to VersionsRetained value, and excess ones (oldest first) are marked for deletion upon next run of script. Can specify a delete to recycle bin (default) or a destructive delete of the backup. 

Use at your own risk.


Script:

function create-7zip([String] $aDirectory, [String] $aZipfile){
	[string]$pathToZipExe = "C:\Program Files\7-zip\7z.exe";
	[Array]$arguments = "a", "-tzip", "$aZipfile", "$aDirectory", "-r";
	& $pathToZipExe $arguments;
}
#  Call it by using:
#create-7zip "c:\temp\myFolder" "c:\temp\myFolder.zip"

#************************************************************************************
#************************************************************************************
# Initialize variables
$zipFolder = "C:\ZipFiles"
$nameConv = "{0:yyyyMMdd_HHmmss}" -f (Get-Date) + ".zip"
$fileList = @{}
$FileCountArray = @()
$bkupTypeArr = @()
$myDocFolder = "c:\Documents and Settings\MyPC\My Documents\"

# Import text files for master, folder and file backup information
$bkupRotateMasterArr = Import-Csv $myDocFolder"RotateBackups_MasterList.txt"
$fldrBkupArray = Import-Csv $myDocFolder"RotateBackups_FolderList.txt"
$fileExtBkupArr = Import-Csv $myDocFolder"RotateBackups_FileExtensions.txt"

# Switch to delete Item or to send to recycle bin
#      delete is destructive and cannot recover file.  
#      Recycle setting removes file from folder, but sends to recycle bin
#      and can be restored if needed.
#      Must be either "Kill" or "Recycle"
$KillOrRecycle = "Recycle"
#************************************************************************************
#************************************************************************************

# Load contents of master backup array
$bkup_Counts = @{}
$b = $null
foreach($b in $bkupRotateMasterArr) 
{
	$bkup_Counts[$b.BackupName] = $b.VersionsRetained
} 


#set Backup Types from the array we just defined
$type = $null
foreach ($type in $bkup_Counts.Keys) {
	$bkupTypeArr += $type
}

#create array of our filenames for this batch
$type = $null
$fArray = @{}
foreach ($type in $bkupRotateMasterArr) {
	$fArray[$type.BackupName] = ($type.BackupName + $nameConv)
}

# if extension array not null, get list of files to back up
if ($fileExtBkupArr) { 
	#  Gather the list of files to be backed up
	$f = $null 
	foreach ($f in $fileExtBkupArr) {
		$arr = @()
		$arr = (Get-ChildItem $f.FolderLoc -Recurse -Include $f.FileExtension | Select-Object fullname)
		foreach ($a in $arr) {
			if ($a) {
				$fileList[$a] = $f.BackupName
			} # if $a not null
		} # end inner foreach
	} # end outer foreach
} # if FileExtension Backup Array not null


# if filelist count gt zero, then create zip file of them for appropriate backup
if ($fileList.Count -gt 0) { # must have entries in hashtable
	$f = $null
	#Loop thru file list & associate file with the appropriate backup
	foreach ($f in $fileList.Keys) {
		$arcFile = $null
		if ($fileList.ContainsKey($f)) {
			if ($fArray.ContainsKey($fileList[$f])) {
				$arcFile = $fArray[$fileList[$f]]
				create-7zip $f.FullName $zipFolder\$arcFile
			} #if key in fArray
		} # if key in Filelist
	} # end foreach
} # if hastable not empty

# if folder backup not null then back up folders
if ($fldrBkupArray) { # check if array not null (no entries)
	$f = $null
	#Backup Folders now
	foreach ($f in $fldrBkupArray) {
		$arcFldr = $null
		#if ($fArray.ContainsKey($f[1])) {
		if ($fArray.ContainsKey($f.BackupName)) {
			$arcFldr = $fArray[$f.BackupName]
			create-7zip $f.FolderName $zipFolder\$arcFldr
		} #end if
	} # end foreach
} # end if $fldrBkupArray not null


# if 7zip succeeded, we'll continue 
if ($LASTEXITCODE -gt 0)
{	Throw "7Zip failed" } 
ELSE { # if Exitcode = 0 then continue with job
	# Remove any files with Archive bit = False 
	#    we marked it for deletion in previous run
	Add-Type -AssemblyName Microsoft.VisualBasic
	$files = get-childitem -path $zipFolder
	# we'll delete all files that don't have the archive bit set 
	Foreach($file in $files) { 
		If((Get-ItemProperty -Path $file.fullname).attributes -band [io.fileattributes]::archive)
		{			Write-output "$file is set to be retained" }
		ELSE {
			if ($KillOrRecycle = "Recycle") {
				Write-output "$file does not have the archive bit set. Deleting (Sent to recycle bin)."
				[Microsoft.VisualBasic.FileIO.Filesystem]::DeleteFile($file.fullname,'OnlyErrorDialogs','SendToRecycleBin')
				$output = $_.ErrorDetails
			}
			ELSE {
				Write-output "$file does not have the archive bit set. Deleting."
				remove-item -recurse $file.fullname
				$output =$_.ErrorDetails 
			}
		} 
	} #end Foreach

	# Export BackupCounts to XML 
	$bkup_counts | Export-Clixml bkup_counts.xml

	# Get Number of ZIP files in folder
	$btype = $null
	foreach ($btype in $bkupTypeArr) {
		$FileCountArray += ,@(($btype),(dir $zipFolder\$btype"*.zip").count)
	}

	# Import BkupCounts from XML
	$bkup_Counts = Import-Clixml bkup_counts.xml

	# set Attribute byte on ALL files in zipfolder so we know we'll get the right ones
	attrib $zipFolder"\*" +a 

	$row = $null
	# Get LST & DEF filenames in array & display count
	foreach ($row in $bkup_Counts.Keys) {
		Get-ChildItem -Path $zipFolder -Include $row"*" -Recurse #|
		(			dir $zipFolder\$row"*".zip).count - $bkup_Counts[$row]
		$delfiles = 0
		$delfiles = (dir $zipFolder\$row"*".zip).count - $bkup_Counts[$row]
		if ($delfiles -gt 0) { #sort folder by createdtime 
			# if more than specified nbr of backups present, un-archive excess ones to delete next run.
			dir $zipFolder\$row"*" | sort-object -property {$_.CreationTime} |
			select-object -first $delfiles |
			foreach-object { attrib $_.FULLNAME -A} 
		} # end if delfiles gt 0
	} # End foreach in bkup_counts

} #  End Else Last ExitCode = 0