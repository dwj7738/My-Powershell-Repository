$uri = "http://www.ssa.gov/OACT/babynames/index.html"

#get the data
$data = Invoke-WebRequest $uri

#get the first table
$table = $data.ParsedHtml.getElementsByTagName("table") | Select -first 1
I used the GetElementsByTagName method from the DOM to retrieve all tables and then selected the first one. The table object has some text properties that I could have tried to parse out, but I decided to take a different approach. The table contains rows, which I can get.
#get the rows
$rows = $table.rows
The first item in the collection of rows will be the table header. This data will become my object properties.
#get table headers
$headers = $rows.item(0).children | select -ExpandProperty InnerText
# Now, $headers is an array of strings from each table column. Now the tricky part and there are probably several ways you could approach this. I need to go through the remaining table rows and match up each column with the header and eventually create a custom object. I decided to use a For enumeration to go through each row and then within each row enumerate again using the headers and add each entry into a hash table, which I can eventually turn into a custom object.
#count number of rows
$NumOfRows = $rows | Measure-Object

#enumerate the remaining rows (skipping the header row) and create a custom object
for ($i=1;$i -lt $NumofRows.Count;$i++) {
 #define an empty hashtable
 $objHash=[ordered]@{}
 #get the child rows
 $rowdata = $rows.item($i).children | select -ExpandProperty InnerText 
 for ($j=0;$j -lt $headers.count;$j++) {
    #add each row of data to the hash table using the corresponding
    #table header value
    $objHash.Add($headers[$j],$rowdata[$j])
  } #for

  #turn the hashtable into a custom object
  [pscustomobject]$objHash
} #for
