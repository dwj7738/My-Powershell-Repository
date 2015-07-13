
function Show-xWinEventLogExamples
{
    $path = Join-Path $PSScriptRoot 'Examples\*'
    if ($Host.Name -eq 'Windows PowerShell ISE Host')
    {
        psedit $path
    }
    else
    {
        $files = @()
        foreach ($f in dir $path)
        {
            $files += "$($f.FullName)"
        }
        PowerShell_ise -file $($files -join ",")
    }
}