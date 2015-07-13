param([Hashtable]$Options)

#region Core ISE Commands
Set-StrictMode -Off

$unsupportedHost = $false
if ($host.Name -eq "PowerGUIScriptEditorHost") {
	$script:pgSE = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance 
	. $psScriptRoot\Add-PowerGUIMenu.ps1
	Set-Alias -Name Add-Menu -Value Add-PowerGUIMenu
} elseif ($Host.Name -eq "Windows PowerShell ISE Host") {
	. $PSScriptRoot\Add-IseMenu.ps1
	Set-Alias -Name Add-Menu -Value Add-IseMenu	
} else {
	Write-Warning 'IsePack is unsupported in this host'
    $unsupportedHost = $true
}

#region Icicles
. $psScriptRoot\Add-Icicle.ps1
. $psScriptRoot\Clear-Icicle.ps1
. $psScriptRoot\Get-Icicle.ps1
. $psScriptRoot\Hide-Icicle.ps1
. $psScriptRoot\Import-Icicle.ps1
. $psScriptRoot\Remove-Icicle.ps1
. $psScriptRoot\Show-Icicle.ps1
. $psScriptRoot\Switch-Icicle.ps1
#endregion Icicles



. $psScriptRoot\Add-ForeachStatement.ps1
. $psScriptRoot\Add-IfStatement.ps1
. $psScriptRoot\Add-InlineHelp.ps1
. $psScriptRoot\Add-Parameter.ps1
. $psScriptRoot\Add-CommentHelp.ps1
. $psScriptRoot\Add-PInvoke.ps1
. $psScriptRoot\Add-SwitchStatement.ps1
. $PSScriptRoot\Add-TextToCurrentDocument.ps1
. $psScriptRoot\Close-AllOpenedFiles.ps1
. $psScriptRoot\ConvertTo-ISEAddon.ps1
. $psScriptRoot\ConvertTo-ShortcutKeyTable.ps1
. $PSScriptRoot\Edit-Script.ps1
. $psScriptRoot\Get-CurrentDocument.ps1
. $psScriptRoot\Get-ScriptToken.ps1
. $psScriptRoot\Get-CurrentOpenedFileToken.ps1
. $psScriptRoot\Get-CurrentOpenedFileText.ps1
. $psScriptRoot\Get-CurrentToken.ps1
. $PSScriptRoot\Get-CurrentDocumentEditor.ps1
. $PSScriptRoot\Get-CurrentScriptPath.ps1
. $PSScriptRoot\Get-EditorCaretPosition.ps1
. $psScriptRoot\Update-ScriptPalette.ps1
. $psScriptRoot\Write-CommandSplatter.ps1
. $psScriptRoot\Save-Function.ps1
. $psScriptRoot\Select-CurrentText.ps1
. $psScriptRoot\Select-CurrentTextAsType.ps1
. $psScriptRoot\Switch-SelectedCommentOrText.ps1
. $psScriptRoot\Show-Member.ps1
. $psScriptroot\Show-TypeConstructor.ps1
. $psScriptroot\Show-TypeConstructorForCurrentType.ps1
. $psScriptRoot\Colorize.ps1
. $psScriptRoot\Get-LastOutput.ps1
. $psScriptRoot\Show-LastOutput.ps1

if (-not $unsupportedHost) {
    Add-Menu -name "_IsePack" -menuFile "$psScriptRoot\Menus\IsePack.Menu.ps1"
}

#region Commands That Will Only Run If The Module is "Online"
$storageAccount = Get-SecureSetting -Name AzureStorageAccountName -ValueOnly
if (-not $storageAccount) {
    $storageAccount = Get-WebConfigurationSetting -Setting AzureStorageAccountName
}
$storageKey = Get-SecureSetting -Name AzureStorageAccountKey -ValueOnly
if (-not $storageKey) {
    $storageKey = Get-WebConfigurationSetting -Setting AzureStorageAccountKey
}

if ($storageAccount -and $storageKey) {
    $isePackTable = Get-AzureTable -TableName IsePack -StorageAccount "$storageAccount" -StorageKey "$storageKey" -ErrorAction SilentlyContinue
    if ($isePackTable) {
        # Connected!


        $script:TableName = 'IsePack'
        $script:UserTableName ='IsePackUsers'


        if ($options.Clean -or (-not (Test-Path "$psScriptRoot\Crud.ps1"))) {
            $Crud = 
                Write-CRUD -Table $script:TableName  -LargeField Description, Icicle -RequiredField Name, Author, Icicle -Partition PowerShellIcicle -Noun PowerShellIcicle -Field @{
                    Name = "The name of the icicle"
                
                    Description = "A description of the icicle"
                    Keyword = "Any keywords for the icicle"
                    Icicle = "The icicle content"                            
                } -FieldOrder Name, Author, Keyword, Description, Icicle -DoNotConnect -TypeName IcicleInfo -DoNotConvertMarkdown 

            $Crud += 
                Write-CRUD -Table $script:TableName  -LargeField Description, Walkthru -RequiredField Name, Author, Walkthru -Partition PowerShellWalkthru -Noun PowerShellWalkthru  -Field @{
                    Name = "The name of the walkthru"                
                    Description = "A description of the walkthru"
                    Keyword = "Any keywords for the walkthru"
                    Walkthru = "The walkthru content"                            
                } -FieldOrder Name, Author, Keyword, Description, Icicle -DoNotConnect -TypeName IseWalkthru -DoNotConvertMarkdown 
       
            $crud +=
                Write-CRUD -Table $script:TableName -RequiredField Name, Url -LargeField Description -Partition PowerShellLink -Noun PowerShellLink -TypeName http://schema.org/Article  -Field @{
                    Name = "The name of the link"
                    Description = "A description of the link"
                    Url = "The link"
                    Author = "The author of the link"
                    Image = "An image to use for the link"
                } -FieldOrder Name, Url, Description, Author, Image

            $crud +=
                Write-CRUD -Table $script:TableName -RequiredField Name, Url -LargeField Description -Partition PowerShellVideo -Noun PowerShellVideo -TypeName http://schema.org/VideoObject  -Field @{
                    Name = "The name of the video"
                    Description = "A description of the video"
                    Url = "A link to the video"
                    Author = "The author of the video"
                    Image = "An image to use for the video"
                } -FieldOrder Name, Url, Description, Author, Image
                        

            $Crud|
                Set-Content "$psScriptRoot\Crud.ps1"

        }
    
        . $psScriptRoot\Crud.ps1

        Export-ModuleMember -Function *

    }
}
#endregion Commands That Will Only Run If The Module is "Online"




$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if ($psise) {
        Clear-Icicle -Confirm:$false
        $menu = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq '_IsePack' }  
        if ($menu) {
            $null = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($menu)
        }

    }
}