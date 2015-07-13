function Show-JeaPresentation
{
    $path = Join-Path $PSScriptRoot 'docs\jea.pptx'
    Invoke-item $path
}

function show-JeaWhitePaper
{
    $path = Join-Path $PSScriptRoot 'docs\Just Enough Administration.docx'
    Invoke-item $path
}

function Show-JeaExamples
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