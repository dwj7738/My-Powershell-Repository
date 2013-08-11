##Created by Felipe Binotto
##On the 6th of October of 2010

##Script to generate report of members of each application group.


$style = @'
<style>
body { background-color:#EEEEEE; }
body,table,td,th { font-family:Tahoma; color:Black; Font-Size:10pt }
th { font-weight:bold; background-color:#AAAAAA; }
td { background-color:white; }
</style>
'@

& {
	"<HTML><HEAD><TITLE>Application Groups</TITLE>$style</HEAD>"
	"<BODY><h2>Report listing all members of all Application Groups</h2><br /><h3>Generated at"
	get-date
	$groups = Get-QADGroup -SearchRoot 'staff.vuw.ac.nz/VUW_Groups/Applications'
	Foreach($group in $groups){
		Get-QADGroupMember $group | select $group.name, name | ConvertTo-HTML $group.name, name -head $style }
	'</BODY></HTML>' 
} | Out-File d:\appgroups.html -Append
ii d:\appgroups.html