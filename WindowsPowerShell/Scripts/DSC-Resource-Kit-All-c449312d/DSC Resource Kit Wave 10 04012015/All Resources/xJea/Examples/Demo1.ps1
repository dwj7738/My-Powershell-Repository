cls

configuration Demo1
{
    Import-DscResource -module xjea

    xJeaToolKit Process
    {
        Name         = 'Process'
        CommandSpecs = @"
Name,Parameter,ValidateSet,ValidatePattern
Get-Process
Get-Service
Stop-Process,Name,calc;notepad
Restart-Service,Name,,^A
"@
    }
    xJeaEndPoint Demo1EP
    {
        Name                   = 'Demo1EP'
        Toolkit                = 'Process'
        SecurityDescriptorSddl = 'O:NSG:BAD:P(A;;GX;;;WD)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)'                                  
        DependsOn              = '[xJeaToolKit]Process'
    }
}

Demo1 -OutputPath C:\JeaDemo

Start-DscConfiguration -Path C:\JeaDemo -ComputerName localhost -Verbose -wait -debug

start-sleep -Seconds 30 #Wait for WINRM to restart

$s = New-PSSession -cn . -ConfigurationName Demo1EP
Invoke-command $s {get-command} |out-string
Invoke-Command $s {get-command stop-process -Syntax}
# Enter-pssession $s

Remove-PSSession $s
#EOF
