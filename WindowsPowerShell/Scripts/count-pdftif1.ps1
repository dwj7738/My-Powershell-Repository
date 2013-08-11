Get-ChildItem "e:\documents\" -Include "*.pdf", "*.tif" -Recurse |
  Group-Object -Property PSParentPath | % {
		$cnt = $_.Group | Group-Object Extension -AsHashTable
		"$($_.Group[0].PsParentPath -replace 'Microsoft.PowerShell.Core\\FileSystem::'):`t" +
		           "`tPDF: " + $cnt.".pdf".count + "`tTIF: " + $cnt.".tif".count
	} | out-file "C:\Temp\Results.txt"
                                            