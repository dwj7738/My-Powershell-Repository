
$myModule = Get-PSCallStack | 
    Where-Object { $_.InvocationInfo.MyCommand.Module } | 
    Select-Object -First 1 -ExpandProperty InvocationInfo | 
    Select-Object -ExpandProperty MyCommand | 
    Select-Object -ExpandProperty Module


$moduleRoot = Split-Path $myModule.Path

$iseMan= [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\IseMan.Icicle.ps1' -Force"
)

$showClock = [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Clock.Icicle.ps1' -Force"
)

$showToDo = [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Todo.Icicle.ps1' -Force"
) 

$showRegions = [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Regions.Icicle.ps1' -Force"
)

 


$showPasty =  [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Pasty.Icicle.ps1' -Force"
) 

$showPipeworks =  [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Pipeworks.Icicle.ps1' -Force"
) 

$findInFiles=  [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Find.Icicle.ps1' -Force"
)

$randomizer=  [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\Randomizer.Icicle.ps1' -Force"
) 


@{
	"Edit" =  . $moduleRoot\Menus\Edit.Menu.ps1
    "Show" = @{
        "Show-Regions" = $showRegions |
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+R" -PassThru        
        "Show-Member" = {
		    Show-Member
	    } |
            Add-Member NoteProperty ShortcutKey "ALT+M" -PassThru        
        "Show-SyntaxForCurrentCommand" = {
		    Show-SyntaxForCurrentCommand
	    } |
            Add-Member NoteProperty ShortcutKey "ALT+Y" -PassThru
        "Show-Clock" = $showClock 
        "Show-ToDo" = $showToDo |
            Add-Member NoteProperty ShortcutKey "ALT+T" -PassThru

        "Pipeworks" = $showPipeworks  |
            Add-Member NoteProperty ShortcutKey "CTRL+P" -PassThru            
        "Show-LastOutput" = {
            Show-LastOutput
        } |
            Add-Member NoteProperty ShortcutKey "ALT+O" -PassThru            
        "Show-TypeConstructorForCurrentType" = {
		    Show-TypeConstructorForCurrentType
	    } |
            Add-Member NoteProperty ShortcutKey "ALT+C" -PassThru	
        "Pasty" =  $showPasty |
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+V" -PassThru	
        "Randomizer" =  $randomizer |
            Add-Member NoteProperty ShortcutKey "CTRL+SHIFT+ALT+R" -PassThru	
        "IseMan" = $iseMan|
            Add-Member NoteProperty ShortcutKey "ALT+I" -PassThru	
            
    }
	"Close-AllOpenedFiles" = { Close-AllOpenedFiles } |
        Add-Member NoteProperty ShortcutKey "CONTROL+SHIFT+F4" -PassThru		

    "Write-FormatView" = {
        Add-Icicle -Command (Get-command Write-FormatView) -Force
    } | Add-Member NoteProperty ShortcutKey "CONTROL+ALT+F" -PassThru

    "Write-TypeView" = {
        Add-Icicle -Command (Get-command Write-TypeView) -Force
    } | Add-Member NoteProperty ShortcutKey "CONTROL+ALT+T" -PassThru
			
    "Find-InFiles" = $findInFiles |
        Add-Member NoteProperty ShortcutKey "CONTROL+SHIFT+F" -PassThru
    "Search-Bing" = {
        $Shell = New-Object -ComObject Shell.Application
        Select-CurrentText | Where-Object { $_ } | ForEach-Object {
            $shell.ShellExecute("http://www.bing.com/search?q=$_")
        } 
    } | Add-Member NoteProperty ShortcutKey "CONTROL+B" -PassThru	
	"Write-_UI" = @{
		'Show-Selection' = {
            Select-CurrentText -NotInOutput -NotInCommandPane | 
                Where-Object { 
                    $_ 
                } |
                ForEach-Object { 
                    $sb = [ScriptBlock]::Create($_)
                    Invoke-Expression "$sb -Show"
                }
                
        } | Add-Member NoteProperty ShortcutKey 'ALT+F8' -PassThru

        'Show-Selection -AsJob' = {
            Select-CurrentText -NotInOutput -NotInCommandPane | 
                Where-Object { 
                    $_ 
                } |
                ForEach-Object { 
                    $sb = [ScriptBlock]::Create($_)
                    Invoke-Expression "$sb -AsJob"
                }
                
        } | Add-Member NoteProperty ShortcutKey 'CONTROL+ALT+F8' -PassThru
	}
}

