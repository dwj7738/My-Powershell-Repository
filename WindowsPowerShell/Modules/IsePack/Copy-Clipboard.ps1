function Copy-Clipboard 
{
    param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [String]
    $Text
    )
    
    begin {
        $null = [Reflection.Assembly]::Load("PresentationCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
    }
    
    process {
        if ([Runspace]::DefaultRunspace.ApartmentState -ne 'STA') {
            
        }
    }
}