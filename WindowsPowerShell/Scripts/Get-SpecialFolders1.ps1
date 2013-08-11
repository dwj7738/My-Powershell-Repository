<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>
## 
# Start of Script 
## 
 
# Get the list of special folders 
$folders = [system.Enum]::GetValues([System.Environment+SpecialFolder])  
 
# Display these folders 
"Folder Name            Path" 
"-----------            -----------------------------------------------" 
foreach ($folder in $folders) { 
"{0,-22} {1,-15}"  -f $folder,[System.Environment]::GetFolderPath($folder) 
} 
#End of Script  
