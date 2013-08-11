Function Set-Computerstate {

[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact="High")]

Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a computername")]
[ValidateNotNullorEmpty()]
[string[]]$Computername,
[Parameter(Mandatory=$True,HelpMessage="Enter an action state")]
[ValidateSet("LogOff","Shutdown","Restart","PowerOff")]
[string]$Action,
[Switch]$Force

)
Begin {
    Write-Verbose "Starting Set-Computerstate"

    #set the state value
    Switch ($Action) {
    "LogOff"   { $Flag=0}
    "ShutDown" { $Flag=1}
    "Restart"  { $Flag=2}
    "PowerOff" { $Flag=8}
    }
    if ($Force) {
        Write-Verbose "Force enabled"
        $Flag+=4
    }
} #Begin

Process {
    Foreach ($computer in $Computername) {
        Write-Verbose "Processing $computer"
        $os=Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer

        if ($PSCmdlet.ShouldProcess($computer)) {
            Write-Verbose "Passing flag $flag"
            $os.Win32Shutdown($flag)
        }

    } #foreach
    
} #Process

End {
    Write-Verbose "Ending Set-Computerstate"

} #end


} #close function

Set-Computerstate localhost -action LogOff -WhatIf -Verbose