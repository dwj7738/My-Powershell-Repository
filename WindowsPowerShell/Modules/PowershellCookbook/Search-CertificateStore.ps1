##############################################################################
##
## Search-CertificateStore
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Search the certificate provider for certificates that match the specified
Enhanced Key Usage (EKU.)

.EXAMPLE

Search-CertificateStore "Encrypting File System"

#>

param(
    ## The friendly name of an Enhanced Key Usage
    ## (such as 'Code Signing')
    [Parameter(Mandatory = $true)]
    $EkuName
)

Set-StrictMode -Off

## Go through every certificate in the current user's "My" store
foreach($cert in Get-ChildItem cert:\CurrentUser\My)
{
    ## For each of those, go through its extensions
    foreach($extension in $cert.Extensions)
    {
        ## For each extension, go through its Enhanced Key Usages
        foreach($certEku in $extension.EnhancedKeyUsages)
        {
            ## If the friendly name matches, output that certificate
            if($certEku.FriendlyName -eq $ekuName)
            {
                $cert
            }
        }
    }
}
