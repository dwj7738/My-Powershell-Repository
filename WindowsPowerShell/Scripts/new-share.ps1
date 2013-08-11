function New-Share {
    param($Path, $Name)

    try {
        $ErrorActionPreference = 'Stop'

        if ( (Test-Path $Path) -eq $false) {
            $null = New-Item -Path $Path -ItemType Directory
        } 
        net share $Name=$Path
    }
    catch {
        Write-Warning "Create Share: Failed, $_"
    }
}
.\