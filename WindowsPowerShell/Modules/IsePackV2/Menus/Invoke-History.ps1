{	
New-ListBox -MaxHeight 400 -MaxWidth 300 -ItemsSource @(Get-History) -On_MouseDoubleClick {
    $window.Close()
} -ItemTemplate {
    New-StackPanel -Orientation Horizontal { 
        $tbParams = @{MaxWidth=200;TextWrapping='Wrap'}
        New-TextBlock @tbParams -Name 'Id'
        New-Label " "
        New-TextBlock @tbParams -Name 'CommandLine'
    } | ConvertTo-DataTemplate -binding @{
        'Id.Text' = 'Id'
        'CommandLine.Text' = 'CommandLine'
    }  
} -show | 
    Invoke-History
                
        } | Add-Member NoteProperty ShortcutKey "F7" -PassThru