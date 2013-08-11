# how to use this
# filename.ps1 inputfilename > outputfilename
# note no error checking is left for the user excersize
$infile = args[1]
$text = get-content $infile
foreach ($line in $text) {
$line1 = $line.trimstart("""CN=")
$pos = $line1.IndexOf(",")
$wanted = $line1.Substring(0, $pos) 
$wanted
}