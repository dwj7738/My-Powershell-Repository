#Twitbrain Cheat PowerShell script
#Description: PowerShell script to beat everyone at the Twitter twitbrain game
#             For more info follow @twitbrain at www.twitter.com
#Change the Twitter Username and Password in the script.
#Author: Stefan Stranger
#Website: http://tinyurl.com/sstranger
#Date: 03/07/2009
#Version: 0.1
#Function Publish-Tweet from James O'Neills blog (http://blogs.technet.com/jamesone/archive/2009/02/16/how-to-drive-twitter-or-other-web-tools-with-powershell.aspx)


[System.Reflection.Assembly]::LoadWithPartialName(?System.Web) | Out-Null

Function Publish-Tweet([string] $TweetText)
{
	[System.Net.ServicePointManager]::Expect100Continue = $false
	$request = [System.Net.WebRequest]::Create("http://twitter.com/statuses/update.xml")
	$Username = "username"
	$Password = "password"
	$request.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
	$request.Method = "POST"
	$request.ContentType = "application/x-www-form-urlencoded" 
	write-progress "Tweeting" "Posting status update" -cu $tweetText

	$formdata = [System.Text.Encoding]::UTF8.GetBytes( "status=" + $tweetText )
	$requestStream = $request.GetRequestStream()
	$requestStream.Write($formdata, 0, $formdata.Length)
	$requestStream.Close()
	$response = $request.GetResponse()

	write-host $response.statuscode 
	$reader = new-object System.IO.StreamReader($response.GetResponseStream())
	$reader.ReadToEnd()
	$reader.Close()
}

Function Waiting()
{
 #Change $a if you want to wait longer or shorter
for ($a = 15; $a -gt 1; $a--) 
{
	Write-Progress -Activity "Waiting for next poll" `
	-SecondsRemaining $a -Status "Please wait."
	Start-Sleep 1
}
}

Write-Host "You are going to cheat;-)"
$strResponse = Read-Host "Are you sure you want to continue? (Y/N)"

if ($strResponse -eq 'N')
{
	Write-host "Maybe a good choice. It has to be a fair competition ;-)"
	break
}

#infinite loop
#Quit script by using Ctrl-C
for (;;)
{
	#Retrieve sum from Twitbrain website
	Write-host "Get calculation from Twitbrain website"
	$ws = New-Object net.WebClient

	#Download Twitbrain website
	$html = $ws.DownloadString("http://ajaxorized.com/twitbrain")

	#Save website content to temporarily file.
	$currentdir = [Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
	$html | Set-Content "$currentdir\Twitbrain.html"

	$twitbrainpage = Get-Content "$currentdir\Twitbrain.html" | out-string

	#Search for calculation string in web page
	$calc = [regex]::match($twitbrainpage,'(?<=\<div class="challenge"\>).+(?=\</div>
			<p class="challenge-answer">)',"singleline").value.trim()

	#search/replace					
	$calc = $calc -replace "\*times\*","*"
	$calc = $calc -replace "\+plus\+","+"
	$calc = $calc -replace "\-minus\-","-"

	#Do the math on the sum
	$result = invoke-expression $calc

	#Create tweet to post to twitter
	$tweet = "@twitbrain " + $result

	#Post to Twitter
	#Check if result has not been posted earlier.
	$oldresult = Get-Content "$currentdir\oldresult.txt"
	if ($result -eq $oldresult)
	{
		write-host "No new Twitbrain question is published yet"
	}
	else 
	{
		Write-host "What is the result of the next question?"
		Write-host $calc
		Publish-Tweet $tweet
		write-host "Tweet publised"
		#Write old result to text file
		$oldresult = $result
		Write-host "Save oldresult to text file"
		$oldresult > "$currentdir\oldresult.txt"
	}

	#Wait 15 seconds
	#Call Waiting Function
	Waiting
}