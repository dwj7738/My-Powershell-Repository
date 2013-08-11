##############################################################################
##
## Send-MailMessage
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
## Illustrate the techniques used to send an email in PowerShell.
## In version two, use the Send-MailMessage cmdlet.
##
## Example:
##
## PS >$body = @"
## >> Hi from another satisfied customer of The PowerShell Cookbook!
## >> "@
## >>
## PS >$to = "guide_feedback@leeholmes.com"
## PS >$subject = "Thanks for all of the scripts."
## PS >$mailHost = "mail.leeholmes.com"
## PS >Send-MailMessage $to $subject $body $mailHost
##
##############################################################################

param(
    ## The recipient of the mail message
    [string[]] $To = $(throw "Please specify the destination mail address"),

    ## The subjecty of the message
    [string] $Subject = "<No Subject>",

    ## The body of the message
    [string] $Body = $(throw "Please specify the message content"),

    ## The SMTP host that will transmit the message
    [string] $SmtpHost = $(throw "Please specify a mail server."),

    ## The sender of the message
    [string] $From = "$($env:UserName)@example.com"
)

## Create the mail message
$email = New-Object System.Net.Mail.MailMessage

## Populate its fields
foreach($mailTo in $to)
{
    $email.To.Add($mailTo)
}

$email.From = $from
$email.Subject = $subject
$email.Body = $body

## Send the mail
$client = New-Object System.Net.Mail.SmtpClient $smtpHost
$client.UseDefaultCredentials = $true
$client.Send($email)
