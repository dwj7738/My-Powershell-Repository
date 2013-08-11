$myModule = Get-PSCallStack | 
    Where-Object { $_.InvocationInfo.MyCommand.Module } | 
    Select-Object -First 1 -ExpandProperty InvocationInfo | 
    Select-Object -ExpandProperty MyCommand | 
    Select-Object -ExpandProperty Module

$moduleRoot = Split-Path $myModule.Path

$showHistoryIcicle= [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\History.Icicle.ps1' -Force"
)


$newPipeworksManifestIcicle = [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\NewPipeworksManifest.Icicle.ps1' -Force"
)

$addParameter = [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\AddParameter.Icicle.ps1' -Force"
) 

$addCommentHelp= [ScriptBlock]::Create(
    "Import-Icicle -File '$moduleRoot\Icicles\AddCommentHelp.Icicle.ps1' -Force"
) 
@{
        "Clear-Output"  = {cls} | Add-Member NoteProperty ShortcutKey "F12" -PassThru
        "Copy-Colored" = {Copy-Colored} |
            Add-Member NoteProperty ShortcutKey "CONTROL+SHIFT+C" -PassThru
        "Copy-ColoredAsHtml" = {Copy-ColoredHTML} |
            Add-Member NoteProperty ShortcutKey "CONTROL+ALT+SHIFT+C" -PassThru
        "Move-ToNextGroup" = {Move-ToNextGroup} |
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+SHIFT+RIGHT" -PassThru
        "Move-ToLastGroup" = {Move-ToLastGroup} |
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+SHIFT+LEFT" -PassThru
        "AutoSave" = {
            $ed = Get-CurrentDocumentEditor 
			$text = $ed | 
                Select-Object -ExpandProperty Editor|
                Select-Object -ExpandProperty Text
			$scriptBlock = [ScriptBlock]::Create($text)
			if (-not $scriptBlock) {
				Write-Error "Could not automatically save the function because the file could not be parsed"
				return
			}
			$func = Save-Function -ScriptBlock $scriptBlock -Passthru 
            if ($func) {               
                $func | 
                    Edit-Script
            }
        } | 
            Add-Member NoteProperty ShortcutKey "CONTROL+F12" -PassThru


                    
        "Add-Parameter" = $addParameter | 
            Add-Member NoteProperty ShortcutKey "ALT+P" -PassThru

        "Add-CommentHelp" = $AddCommentHelp | 
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+H" -PassThru
        "Invoke-History" =  $showHistoryIcicle |
            Add-Member NoteProperty ShortcutKey "F7" -PassThru

        "New-PipeworksManifest" =  $newPipeworksManifestIcicle|
            Add-Member NoteProperty ShortcutKey "CTRL+ALT+P" -PassThru
		
    }