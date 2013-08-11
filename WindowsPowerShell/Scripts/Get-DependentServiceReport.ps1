<#

            .SYNOPSIS

            Script to retrieve information about services.

      .EXAMPLE

            .\Get-DependentServiceReport.ps1

            Retrieve all services running on the local computer that can be Paused.

      .EXAMPLE

            .\Get-ServiceInfo.ps1 -CurrentState All -GridView
	Use PowerShell to Identify Services Dependent on Windows
            Retrieve all services running on the local computer and display in a GridView.     

      .EXAMPLE

            .\Script.ps1 -Services S* -ComputerName <computername> -CurrentState CanStop -Sort DisplayName

            Retrieve all services starting with S, on a remote computer, that can be stopped, and sort by the DisplayName.

      .NOTES

            NAME: Get-ServiceInfo.ps1

            AUTHOR: Brandon Shell

            DATE: 3rd April 2011

#Requires -Version 2.0


# To get a report from a single machine
# Get-DependentServiceReport MyServerX
#
# To get a report from all the machines in a text file
#get-content C:\data\myservers.txt | Get-DependentServiceReport
#
# To get a report from all servers in a domain with at least one 2008 R2 domain controller
#Get-ADComputer -Filter {operatingSystem -like "*Server*"} | Get-DependantServiceReport
#
# To get a report from all servers using adfind
#c:\tools\AdFind.exe -f 'operatingsystem=*server*' dnshostname -list | Get-DependantServiceReport

# To get a report using the all servers using Quest AD cmdlets

Get-QADComputer -OSName *Server* | Get-DependantServiceReport
#>
 function Get-DependentServiceReport
{
    [Cmdletbinding()]
    Param(
        [alias('ComputerName')]
        [Parameter(ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True)]
        [string]$DNSHostName = $Env:COMPUTERNAME
    )
    process 
    {
        ""
        $Message = "****** {0} ******" -f $DNSHostName
        "*" * $Message.Length
        $Message
        "*" * $Message.Length
        ""

        $Services = Get-Service -ComputerName $DNSHostName
        foreach($Service in $Services)
        {
            "{0}" -f $Service.DisplayName
            "-" * ($Service.DisplayName).Length
            "{0,-20} {1,-60} {2}" -f $Service.Name,$Service.DisplayName,$Service.Status
            $Dependents = $Service | Get-Service -DependentServices -ComputerName $DNSHostName
            if($Dependents)
            {
                foreach($Dependent in $Dependents)
                {
                    "{0,-20} {1,-60} {2}" -f $Dependent.Name,$Dependent.DisplayName,$Dependent.Status
                }
            }
            ""
        }
    
    }
}