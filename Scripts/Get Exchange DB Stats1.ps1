# requires -version 2.0
#
# get-exstats.ps1
#
# returns various statistics on databases
#
# Author: rfoust@duke.edu
# Modified: March 12, 2012
#
# This has only been tested with Exchange 2010

param([string]$server = $env:computername.tolower(), [string]$database = "NotSpecified", [switch]$all, [switch]$noemail, [switch]$nologcheck)

#Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
if (!(get-pssnapin Microsoft.Exchange.Management.PowerShell.E2010 -erroraction silentlycontinue))
{
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
}

# found this really cool function here: http://www.olavaukan.com/tag/powershell/
function Util-Convert-FileSizeToString { 
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
		[int64]$sizeInBytes
	)

	switch ($sizeInBytes)
	{
		{			$sizeInBytes -ge 1TB} {"{0:n$sigDigits}" -f ($sizeInBytes / 1TB) + " TB" ; break}
		{			$sizeInBytes -ge 1GB} {"{0:n$sigDigits}" -f ($sizeInBytes / 1GB) + " GB" ; break}
		{			$sizeInBytes -ge 1MB} {"{0:n$sigDigits}" -f ($sizeInBytes / 1MB) + " MB" ; break}
		{			$sizeInBytes -ge 1KB} {"{0:n$sigDigits}" -f ($sizeInBytes / 1KB) + " KB" ; break}
		Default { "{0:n$sigDigits}" -f $sizeInBytes + " Bytes" }
	}
}


# specifying only a single database using -database makes the script run faster for testing
if ($database -eq "NotSpecified")
{
	# $dbs = get-mailboxdatabase -status | ? { $_.replicationtype -eq "Remote" } | select-object servername,name,databasesize,mounted | sort servername,name
	$dbs = get-mailboxdatabase -status | ? { $_.replicationtype -eq "Remote" } | sort servername,name
}
else
{
	$dbs = get-mailboxdatabase $database -status | sort servername,name
}

$fragments = @() # array to hold html fragments
$data = @() # array to hold the psobjects
$prettydata = @() # array to hold pretty data (strings, not raw bytes)


foreach ($db in $dbs)
{
	write-host "Processing $db."

	$raw = new-object psobject
	$pretty = new-object psobject

	write-host "Gathering count of mailboxes on $db."
	$mailboxes = (get-mailbox -database $db.name -resultsize unlimited).count

	#get copy status
	$copystatus = (get-mailboxdatabasecopystatus $db.name | ? { $_.activecopy -eq $false }).status

	if (-not $nologcheck)
	{
		#figure out how much space the logs are consuming
		# $drive will probably end up being D$ in all cases, but might as well do the logic to figure it out
		write-host "Finding out how much disk space the log files are using for $db ..."
		$drive = $db.logfolderpath.tostring().substring(0,1) + "$"
		$substring = $db.logfolderpath.tostring().substring(0,2)
		$uncpath = "\\$($db.server)\" + $drive + ($db.logfolderpath.tostring().replace($substring,"")) + "\*.log"
		$logsize = (ls $uncpath | measure-object -property length -sum).sum
		$logsizetotal += $logsize
		$logsize = util-convert-filesizetostring $logsize
	}

	#calculate average mailbox size
	Write-Host "Calculating average mailbox size ..."
	$avg = get-mailboxstatistics -database $db | % { $_.totalitemsize.value.tobytes() }
	$avg = ($avg | Measure-Object -Average).average
	$avgTotal += $avg

	if ($avg)
	{
		$avgPretty = util-convert-filesizetostring $avg
	}

	#calculate deleted mailbox size
	Write-Host "Calculating deleted mailbox size ..."
	$deletedMBsize = get-mailboxstatistics -database $db | ? { $_.DisconnectDate -ne $null } | % { $_.totalitemsize.value.tobytes() }
	$deletedMBsize = ($deletedMBsize | Measure-Object -Sum).sum
	$deletedMBsizeTotal += $deletedMBsize

	if ($deletedMBsize)
	{
		$deletedMBsizePretty = util-convert-filesizetostring $deletedMBsize
	}

	#calculate dumpster size
	Write-Host "Calculating dumpster size ..."
	$dumpster = get-mailboxstatistics -database $db | % { $_.totaldeleteditemsize.value.tobytes() }
	$dumpster = ($dumpster | Measure-Object -Sum).sum
	$dumpsterTotal += $dumpster

	if ($dumpster)
	{
		$dumpsterPretty = util-convert-filesizetostring $dumpster
	}

	#get a shorter db size
	$dbsize = $db.databasesize.tobytes()
	$dbsizetotal += $dbsize
	if ($dbsize)
	{
		$dbsizePretty = util-convert-filesizetostring $dbsize
	}

	#get free space on the mountpoint volume
	$freespace = (gwmi win32_volume -computer $db.server | where { $_.name -eq ($db.logfolderpath.tostring() + "\") }).freespace
	$freespacetotal += $freespace
	if ($freespace)
	{
		$freespacePretty = util-convert-filesizetostring $freespace
	}

	#get capacity on the mountpoint volume
	$capacity = (gwmi win32_volume -computer $db.server | where { $_.name -eq ($db.logfolderpath.tostring() + "\") }).capacity
	$capacitytotal += $capacity
	if ($capacity)
	{
		$capacityPretty = util-convert-filesizetostring $capacity
	}

	#get a shorter whitespace size
	$whitespace = $db.availablenewmailboxspace.tobytes()
	$whitespacetotal += $whitespace
	if ($whitespace)
	{
		$whitespacePretty = util-convert-filesizetostring $whitespace
	}


	# create psobject with raw bytes
	$raw | add-member NoteProperty "ServerName" $db.servername
	$raw | add-member NoteProperty "Database" $db.name
	$raw | add-member NoteProperty "Mailboxes" $mailboxes
	$raw | add-member NoteProperty "CopyStatus" $copystatus
	$raw | add-member NoteProperty "DBSize" $dbsize
	# $raw | add-member NoteProperty "Mounted" $db.mounted
	$raw | add-member NoteProperty "LogSize" $logsize
	$raw | add-member NoteProperty "FreeSpace" $freespace
	$raw | add-member NoteProperty "TotalSpace" $capacity
	$raw | add-member NoteProperty "Whitespace" $whitespace
	$raw | add-member NoteProperty "Deleted Mbox" $deletedMBsize
	$raw | add-member NoteProperty "Dumpster" $dumpster
	$raw | add-member NoteProperty "Avg Mbox" $avgPretty
	$raw | add-member NoteProperty "Last Full Backup" $db.lastfullbackup
	$raw | add-member NoteProperty "Last Incr Backup" $db.lastincrementalbackup

	$data += $raw

	# create psobject with pretty display sizes (MB, GB, etc)
	$pretty | add-member NoteProperty "ServerName" $db.servername
	$pretty | add-member NoteProperty "Database" $db.name
	$pretty | add-member NoteProperty "Mailboxes" $mailboxes
	$pretty | add-member NoteProperty "CopyStatus" $copystatus
	$pretty | add-member NoteProperty "DBSize" $dbsizePretty
	# $pretty | add-member NoteProperty "Mounted" $db.mounted
	$pretty | add-member NoteProperty "LogSize" $logsize
	$pretty | add-member NoteProperty "FreeSpace" $freespacePretty
	$pretty | add-member NoteProperty "TotalSpace" $capacityPretty
	$pretty | add-member NoteProperty "Whitespace" $whitespacePretty
	$pretty | add-member NoteProperty "Deleted Mbox" $deletedMBsizePretty
	$pretty | add-member NoteProperty "Dumpster" $dumpsterPretty
	$pretty | add-member NoteProperty "Avg Mbox" $avgPretty
	$pretty | add-member NoteProperty "Last Full Backup" $db.lastfullbackup
	$pretty | add-member NoteProperty "Last Incr Backup" $db.lastincrementalbackup

	$prettydata += $pretty
}

# add a "total" row
$thingy = new-object psobject
write-host; write-host "Calculating totals ..."

$mailboxes = ($data | measure-object mailboxes -sum).sum
$deletedMBsizetotal = ($deletedMBsizetotal | Measure-Object -Sum).sum

$thingy | add-member NoteProperty "ServerName" "Total"
$thingy | add-member NoteProperty "Database" $data.count
$thingy | add-member NoteProperty "DBSize" (util-convert-filesizetostring $dbsizetotal)
$thingy | add-member NoteProperty "Mailboxes" $mailboxes
if (-not $nologcheck)
{
	$thingy | add-member NoteProperty "LogSize" (util-convert-filesizetostring $logsizetotal)
}
$thingy | add-member NoteProperty "FreeSpace" (util-convert-filesizetostring $freespacetotal)
$thingy | add-member NoteProperty "TotalSpace" (util-convert-filesizetostring $capacitytotal)
$thingy | add-member NoteProperty "Whitespace" (util-convert-filesizetostring $whitespacetotal)
$thingy | Add-Member NoteProperty "Deleted Mbox" (util-convert-filesizetostring $deletedMBsizeTotal)
$thingy | Add-Member NoteProperty "Dumpster" (util-convert-filesizetostring $dumpsterTotal)
#$thingy | Add-Member NoteProperty "Avg Mbox" (util-convert-filesizetostring $avgTotal)

$prettyData += $thingy

# add raw data total row
$thingy = new-object psobject

$mailboxes = ($data | measure-object mailboxes -sum).sum
$deletedMBsizetotal = ($deletedMBsizetotal | Measure-Object -Sum).sum

$thingy | add-member NoteProperty "ServerName" "Total"
$thingy | add-member NoteProperty "Database" $data.count
$thingy | add-member NoteProperty "DBSize" $dbsizetotal
$thingy | add-member NoteProperty "Mailboxes" $mailboxes
if (-not $nologcheck)
{
	$thingy | add-member NoteProperty "LogSize" $logsizetotal
}
$thingy | add-member NoteProperty "FreeSpace" $freespacetotal
$thingy | add-member NoteProperty "TotalSpace" $capacitytotal
$thingy | add-member NoteProperty "Whitespace" $whitespacetotal
$thingy | Add-Member NoteProperty "Deleted Mbox" $deletedMBsizeTotal
$thingy | Add-Member NoteProperty "Dumpster" $dumpsterTotal
#$thingy | Add-Member NoteProperty "Avg Mbox" $avgTotal

$data += $thingy

# dump pretty data out to screen
$prettyData

# bullet graph idea came from here: http://www.usrecordings.com/test-lab/bullet-graph.htm
# powershell html chart was inspired by: http://jdhitsolutions.com/blog/2012/02/create-html-bar-charts-from-powershell/
$style = "<style type=`"text/css`">
html * { margin: 0; padding: 0; border: 0; }
body { text-align: left; font: 10pt Arial, sans-serif; }
TH { border-width: 1px; padding: 0px; border-style: solid; border-color: black; background-color: thistle }
h1 { font: 30pt Arial, sans-serif; padding: 10px 0 5px 0; width: 540px; margin: 0 auto 10px auto; border-bottom: 1px solid #8f8f8f; text-align: left; }
	h2 { font: 20pt Arial, sans-serif; }
	p#contact { font: 10pt Arial, sans-serif; width: 398px; margin: 0 auto; padding-top: 7px; text-align: left; line-height: 140 % ; }
	a:link, a:visited, a:hover { color: rgb(32,108,223); font-weight: bold; text-decoration: none; }
	a:hover { color: #cc0000; font-weight: bold; }


		div#container { position: relative; margin: 0px 50px; padding: 0; text-align: left; top: 80px; width: 250px; }

		/* BULLET GRAPH */
		div.box-wrap { position: relative; width: 200px; height: 21px; top: 0; left: 0; margin: 0; padding: 0; }

		/* CHANGE THE WIDTH AND BACKGROUND COLORS AS NEEDED */
		div.box1 { position: absolute; height: 20px; width: 30 % ; left: 0; background-color: #eeeeee; z-index: 1; font-size: 0; }
			div.box2 { position: absolute; height: 20px; width: 30 % ; left: 30 % ; background-color: #dddddd; z-index: 1; font-size: 0; }
				div.box3 { position: absolute; height: 20px; width: 30 % ; left: 60 % ; background-color: #bbbbbb; z-index: 1; font-size: 0; }
					div.box4 { position: absolute; height: 20px; width: 10 % ; left: 90 % ; background-color: #bbbbbb; z-index: 1; font-size: 0; }

						/* RED LINE */
						div.target { position: absolute; height: 20px; width: 1px; left: 32px; top: 0; background-color: #cc0000; z-index: 7; font-size: 0; }

							/* ONE SEGMENT ONLY */
							div.actual { position: absolute; height: 8px; left: 0px; top: 6px; background-color: #000000; font-size: 0; z-index: 5; font-size: 0; }

								/* TWO SEGMENTS */
								div.actualWhitespace { position: absolute; height: 8px; left: 0px; top: 6px; background-color: #b580fe; font-size: 0; z-index: 5; font-size: 0; }
									div.actualDeleted { position: absolute; height: 8px; left: 0px; top: 6px; background-color: #2d006b; font-size: 0; z-index: 5; font-size: 0; }
										div.actualDumpster { position: absolute; height: 8px; left: 0px; top: 6px; background-color: #dabffe; font-size: 0; z-index: 5; font-size: 0; }
											div.actualData { position: absolute; height: 8px; left: 0px; top: 6px; background-color: #400099; font-size: 0; z-index: 5; font-size: 0; }

												div.mylabel { 
													position: relative; 
													height: 20px; 
													width: 145px; 
													left: -155px; 
													top: 2px; 
													background-color: #fff; 
													z-index: 7; 
													font-size: 0;
													color: #000000; 
													font: 10pt Arial, sans-serif; 
													text-align: right; 
												}

												div.scale-tb1 {
													padding: 0; 
													margin: 0;
													font-size: 0;
													width: 200px;
													border: 0; 
													position: relative; 
													top: 10px; 
													left: 0px; 
													border-top: 1px solid #8f8f8f; 
												}

												div.scale-tb2 {
													padding: 0; 
													margin: 0;
													font-size: 0;
													width: 200px;
													border: 0; 
													position: relative; 
													top: 0px; 
													left: 0px; 
												}

												/* SCALE MARKS */
												div.sc21 { position: absolute; height: 7px; width: 1px; left: 0px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
													div.sc22 { position: absolute; height: 7px; width: 1px; left: 39px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
														div.sc23 { position: absolute; height: 7px; width: 1px; left: 79px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
															div.sc24 { position: absolute; height: 7px; width: 1px; left: 119px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																div.sc25 { position: absolute; height: 7px; width: 1px; left: 159px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																	div.sc26 { position: absolute; height: 7px; width: 1px; left: 199px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }

																		div.sc31 { position: absolute; height: 7px; width: 1px; left: 0px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																			div.sc32 { position: absolute; height: 7px; width: 1px; left: 39px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																				div.sc33 { position: absolute; height: 7px; width: 1px; left: 79px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																					div.sc34 { position: absolute; height: 7px; width: 1px; left: 119px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																						div.sc35 { position: absolute; height: 7px; width: 1px; left: 159px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }
																							div.sc36 { position: absolute; height: 7px; width: 1px; left: 199px; top: 0px; background-color: #8f8f8f; z-index: 7; font-size: 0; }


																								/* SCALE TEXT */
																								div.cap21 { position: absolute; top: 40px; left: -2px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																									div.cap22 { position: absolute; top: 40px; left: 35px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																										div.cap23 { position: absolute; top: 40px; left: 71px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																											div.cap24 { position: absolute; top: 40px; left: 112px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																												div.cap25 { position: absolute; top: 40px; left: 152px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																													div.cap26 { position: absolute; top: 40px; left: 191px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }

																														div.cap31 { position: absolute; top: 29px; left: -2px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																															div.cap32 { position: absolute; top: 29px; left: 35px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																																div.cap33 { position: absolute; top: 29px; left: 71px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																																	div.cap34 { position: absolute; top: 29px; left: 112px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																																		div.cap35 { position: absolute; top: 29px; left: 152px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																																			div.cap36 { position: absolute; top: 29px; left: 191px; width: 15px; font: 8pt Arial, sans-serif; text-align: center; color: #575757; }
																																				</style>"

																																				$fragments += "<H2>Exchange 2010 Statistics</H2>"
																																				$fragments += $prettyData | ConvertTo-Html -fragment
																																				# $fragments += "<br>"

																																				$html = @()

																																				$html += "<div id=`"container`">"
																																				$html += "Database Size Graph"

																																				foreach ($db in $data)
																																				{
																																					if ($db.servername -ne "Total")
																																					{
																																						$html += "<div class=`"box-wrap`">
 <div class=`"box1`"></div>
 <div class=`"box2`"></div>
 <div class=`"box3`"></div>
 <div class=`"box4`"></div>
 <div class=`"target`" style=`"left: $([math]::round((($db.totalspace - $db.freespace) / $db.totalspace) * 100))%`"></div>
 <div class=`"actualWhitespace`" style=`"width: $([math]::round((($db.dbsize) / $db.totalspace)*100))%`"></div>
 <div class=`"actualDeleted`" style=`"width: $([math]::round((($db.dbsize - $db.whitespace) / $db.totalspace)*100))%`"></div>
 <div class=`"actualDumpster`" style=`"width: $([math]::round((($db.dbsize - $db.whitespace - $db.'deleted mbox') / $db.totalspace)*100))%`"></div>
 <div class=`"actualData`" style=`"width: $([math]::round((($db.dbsize - $db.dumpster - $db.'deleted mbox' - $db.whitespace) / $db.totalspace)*100))%`"></div>
 <div class=`"mylabel`">$($db.database)</div>

																																						<div class=`"cap31`">0%</div>
 <div class=`"cap32`">20%</div>
 <div class=`"cap33`">40%</div>
 <div class=`"cap34`">60%</div>
 <div class=`"cap35`">80%</div>
 <div class=`"cap36`">100%</div>	

																																						<div class=`"scale-tb2`">
 <div class=`"sc31`"></div>
 <div class=`"sc32`"></div>
 <div class=`"sc33`"></div>
 <div class=`"sc34`"></div>
 <div class=`"sc35`"></div>
 <div class=`"sc36`"></div>
 </div> 

																																						</div>

																																						<p style=`"height: 30px;`"></p>"
																																					}
																																					else # total row
																																					{
																																						$html += "<div class=`"box-wrap`">
 <div class=`"box1`"></div>
 <div class=`"box2`"></div>
 <div class=`"box3`"></div>
 <div class=`"box4`"></div>
 <div class=`"target`" style=`"left: $([math]::round((($db.totalspace - $db.freespace) / $db.totalspace) * 100))%`"></div>
 <div class=`"actualWhitespace`" style=`"width: $([math]::round((($db.dbsize) / $db.totalspace)*100))%`"></div>
 <div class=`"actualDeleted`" style=`"width: $([math]::round((($db.dbsize - $db.whitespace) / $db.totalspace)*100))%`"></div>
 <div class=`"actualDumpster`" style=`"width: $([math]::round((($db.dbsize - $db.whitespace - $db.'deleted mbox') / $db.totalspace)*100))%`"></div>
 <div class=`"actualData`" style=`"width: $([math]::round((($db.dbsize - $db.dumpster - $db.'deleted mbox' - $db.whitespace) / $db.totalspace)*100))%`"></div>
 <div class=`"mylabel`">Total</div>

																																						<div class=`"cap31`">0%</div>
 <div class=`"cap32`">20%</div>
 <div class=`"cap33`">40%</div>
 <div class=`"cap34`">60%</div>
 <div class=`"cap35`">80%</div>
 <div class=`"cap36`">100%</div>	

																																						<div class=`"scale-tb2`">
 <div class=`"sc31`"></div>
 <div class=`"sc32`"></div>
 <div class=`"sc33`"></div>
 <div class=`"sc34`"></div>
 <div class=`"sc35`"></div>
 <div class=`"sc36`"></div>
 </div> 

																																						</div>

																																						<p style=`"height: 30px;`"></p>"
																																					}
																																				}

																																				# show a graph key
																																				$html += "<div class=`"box-wrap`">
 <div class=`"box1`"></div>
 <div class=`"box2`"></div>
 <div class=`"box3`"></div>
 <div class=`"box4`"></div>
 <div class=`"target`" style=`"left: 90%`"></div>
 <div class=`"actualWhitespace`" style=`"width: 100%`"></div>
 <div class=`"actualDeleted`" style=`"width: 75%`"></div>
 <div class=`"actualDumpster`" style=`"width: 50%`"></div>
 <div class=`"actualData`" style=`"width: 25%`"></div>
 <div class=`"mylabel`">Key:</div>

																																				</div> 
																																				MBs - Dumpster - Del MB - Whitespace<br>
																																				Red Line: Used Disk Space
																																				</div>

																																				<p style=`"height: 30px;`"></p>"

																																				$html += "</div><!-- container -->"
																																				$fragments += $html 
																																				$emailbody = convertto-html -head $style -Body $fragments
																																				$date = get-date -uformat "%Y-%m-%d"

																																				if (-not $noemail)
																																				{
																																					$smtpServer = "your.smtpserver.com"
																																					$msg = new-object Net.Mail.MailMessage
																																					$smtp = new-object Net.Mail.SmtpClient($smtpServer)
																																					$msg.From = "somebody@somewhere.com"
																																					$msg.To.Add("you@somewhere.com")
																																					$msg.Subject = "Exchange 2010 Daily Statistics"
																																					$msg.Body = $emailbody
																																					$msg.IsBodyHtml = $true

																																					$smtp.Send($msg)
																																				}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjqiNj25ul7qyV81h6QZ+0mMc
# y/igggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNcNj4yHdEVNcsCo
# JSnU66aMEFOxMA0GCSqGSIb3DQEBAQUABIIBABh5HlMnAwHpiOj25SSE4OLtw1VO
# 31q8TIaNCEp52aNias0VzUU1EYXPEhW6CJIEOdPZgNs2yfQo/Qt9wfKu5D2hlij+
# F6aKPrDJsRofMOFOxgBLObIZPwKuqpAoafPfbegcByPuTdyNO9jmDEIp4YTi8jo3
# yqH/SjuxuHbpEyOlnVCb/gabqkwarhPYNGe3yCdHts+DS7e6TZWv0dUGSG9puS1U
# mOQ2GVICgl5bz2OtkSIp6XjPIgJ1/lwbXi21GgCoGtV3NFEr3BeEId2KkwKcufBK
# CQMhKZu0szShYltf3GR9RYTc2q3piXaP2Gm8imsOWVsFDKpjHjLEsO2e0vE=
# SIG # End signature block
