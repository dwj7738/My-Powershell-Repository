    Import-Module $env:SystemDrive\Windows\System32\WindowsPowerShell\v1.0\modules\SmbShare\SmbShare.cdxml
    Import-Module $PSScriptRoot\ProxyFunctions.psm1
   
    $IRCommands = @("Get-Command","Out-Default","Exit-PSSession","Measure-Object","Select-Object")

    $allowedCommands = New-Object System.Collections.Generic.List[string]
    foreach ($command in $IRCommands)
    {    
        $allowedCommands.Add($command)
    }

    if($PSSenderInfo.ConnectedUser -eq "Corporate\PAPA")
    {
        $userCommand = @("New-SmbShare","Get-SmbShare","Remove-SmbShare")
        foreach ($Command in $userCommand)
        {
            if ( (Get-Command $command).Count -eq 1)
            {
                $allowedCommands.Add($Command)
            }
            else
            {
                # when the command is a wildcard
                Get-Command $command| %{$allowedCommands.Add($_.Name)}
            }
        }
    }

    if($PSSenderInfo.ConnectedUser -eq "Corporate\User1")
    {
        $userCommand = @("dir","get-content")
        foreach ($Command in $userCommand)
        {
            if ( (Get-Command $command).Count -eq 1)
            {
                $allowedCommands.Add($Command)
            }
            else
            {
                # when the command is a wildcard
                Get-Command $command| %{$allowedCommands.Add($_.Name)}
            }
        }
    }

    $ExecutionContext.SessionState.Applications.Clear()
    $ExecutionContext.SessionState.Scripts.Clear()

    Get-Command | %{$_.Visibility="Private"}

    foreach($command in $allowedCommands)
    {
        Get-Command | ?{$_.Name -like $command} | %{$_.Visibility="Public"}
    }

    $ExecutionContext.SessionState.LanguageMode = "NoLanguage"