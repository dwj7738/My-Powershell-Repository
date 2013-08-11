#Requires –Version 3
<# Let's assume you have a CSV file with information that you need to frequently look up. 
    For example, the CSV file may contain server names and certain configuration settings for them.
To easily look up items in your CSV file, you can turn it into a hash table. 

Let's first create a test CSV file to play with:
#>
# create test CSV file 
# create test CSV file
$file = "$env:temp\testfile.csv"

$content = @'
Servername, Year, ID, Description, Metric
Server12,2012,100,'test',99
Server98,2011,187,'production',61
S_EXCH1,2010,877,'mail',98
MEMS77,2011,300,'data',7
'@

$content | Set-Content -Path $file
#
<#Next, let's turn this CSV file into a lookup table, using the column "Servername" as key column:
# analyzing any CSV file content: 
#>
# analyzing any CSV file content:
$content = Import-CSV $file -Encoding UTF8 
$lookup = $content | Group-Object -AsHashTable -AsString -Property Servername

# listing CSV file keys:
$lookup.Keys
<#
It works! Note how the code uses Group-Object to create the lookup table. 
Note also that its parameter -Property determines the CSV file column it uses to index the information. 
You just need to make sure that the information in this column is unique (has no duplicate entries).
Now it is very easy to lookup information from your CSV file data:
# looking up individual server information: 
$#>
# looking up individual server information:
$lookup['Server98']
$lookup['Server98'].Description

# testing whether a given server is contained in list:
$lookup.Keys -contains 'Server12'
$lookup.Keys -contains 'Server11'
Remove-Item $file
