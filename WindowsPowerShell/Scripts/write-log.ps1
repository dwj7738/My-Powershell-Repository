    Function Write-Log

    {

        Param (

            [String] $Path = $(Join-Path -Path ([environment]::GetFolderPath('myDocuments')) `

                                         -ChildPath 'HSGLogFiles'),

            [Parameter(ValueFromPipeline = $true, Mandatory = $true)]       

            [String] $Message

            )

     

        process

        {

            # File's name generation

            $logName = (Get-Date -Format 'yyyyMMdd') + '_' + $env:username + '.log'

     

            # Testing the existence of the directory containing the log file

            if ( -not (Test-Path $Path) )

            {

                New-Item -Path $Path -ItemType Directory | Out-Null

            }

     

            # Testing the existence of the log file, if it exists we do nothing

            if ( !(Test-Path "$Path\$logName") )

            {

                $Message > $Path\$logName

            }

        }

    }
