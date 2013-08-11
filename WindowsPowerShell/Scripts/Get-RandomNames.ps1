function Get-RandomNames {
<#
.SYNOPSIS
Gets Full Names from a List of Names from http://names.mongabay.com
.DESCRIPTION
Downloads the Names from the Websites and randomizes the order of Names and gives back an Object with surname, lastname and gender
.PARAMETER MaxNames
Number of names returned by the function
.PARAMETER Gender
Gender of the names
.EXAMPLE
Get-RandomNames -Maxnames 20 -Gender Female
.EXAMPLE
Get-RandomNames
.NOTES
Name: Get-RandomNames
Author: baschuel
Date: 17.02.2013
Version: 1.0
Thanks to http://names.mongabay.com
#>
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        [int]$MaxNames = 10,
        [parameter(Position=1)]
        [string]$Gender = "Male"       
    )
    BEGIN{
        $surnameslink = "http:\\names.mongabay.com/most_common_surnames.htm"
		$malenameslink = "http:\\names.mongabay.com/male_names_alpha.htm"
		$femalenameslink = "http:\\names.mongabay.com/female_names_alpha.htm"
    }#begin
    
    PROCESS{
		
		
        function get-names ($url) {
            
            Try {
            
                $web = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction Stop

                $html = $web.Content

                $regex = [RegEx]'((?:<td>)(.*?)(?:</td>))+'

                $Matches = $regex.Matches($html)
            
                $matches | ForEach-Object {
                    If ($_.Groups[2].Captures[0].Value -ge 1) {
                    
                        $hash = @{Name = $_.Groups[2].Captures[0].Value;
                                  Rank = [int]$_.Groups[2].Captures[3].Value}
                        New-Object -TypeName PSObject -Property $hash
                    
                    }#If
                }#Foreach-Object

            } Catch {

                Write-Warning "Can't access the data from $url."
                Write-Warning "$_.Exception.Message"
                Break

            }
            
        }#Function get-names


        If ($Gender -eq "Male") {
            
            $AllMaleFirstNames = (get-Names $malenameslink).name
            $AllSurnames = (get-names $surnameslink).name
            
            If ($AllMaleFirstNames.Count -le $AllSurnames.Count) {
                $UpperRange = $AllMaleFirstNames.Count
            } else {
                $UpperRange = $AllSurnames.Count
            }
            

            If (($MaxNames -le $AllMaleFirstNames.Count) -and ($MaxNames -le $AllSurnames.Count)) {

                1..$UpperRange | 
                Get-Random -Count $MaxNames | 
                ForEach-Object {
                    $hash = @{Givenname = $AllMaleFirstNames[$_];
                              Surname = $AllSurnames[$_];
                              Gender = "Male"}
                    
                    $hash.Givenname = $($hash.Givenname[0]) + $hash.givenname.Substring(1,$hash.givenname.Length-1).ToLower()
                    $hash.Surname = $($hash.Surname[0]) + $hash.surname.Substring(1,$hash.surname.Length-1).ToLower()
                    
                    New-Object -TypeName PSObject -Property $hash
                } # Foreach-Object

            } Else {
    
                Write-Warning "Don't know so many names! Try a smaller number"

            }#If

        } elseIf ($Gender -eq "Female") {
        
            $AllFeMaleFirstNames = (get-Names $femalenameslink).name
            $AllSurnames = (get-names $surnameslink).name
            
            If ($AllFeMaleFirstNames.Count -le $AllSurnames.Count) {
                $UpperRange = $AllMaleFirstNames.Count
            } else {
                $UpperRange = $AllSurnames.Count
            }
            If (($MaxNames -le $AllFeMaleFirstNames.Count) -and ($MaxNames -le $AllSurnames.Count)) {

                1..$UpperRange | 
                Get-Random -Count $MaxNames | 
                ForEach-Object {
                    $hash = @{Givenname = $AllFeMaleFirstNames[$_];
                              Surname = $AllSurnames[$_];
                              Gender = "Female"}
                    
                    $hash.Givenname = $($hash.Givenname[0]) + $hash.givenname.Substring(1,$hash.givenname.Length-1).ToLower()
                    $hash.Surname = $($hash.Surname[0]) + $hash.surname.Substring(1,$hash.surname.Length-1).ToLower()
                    
                    New-Object -TypeName PSObject -Property $hash
                } # Foreach-Object

            } Else {
    
                Write-Warning "Don't know so many names! Try a smaller number"

            }#If
        }#If
        
    }

}