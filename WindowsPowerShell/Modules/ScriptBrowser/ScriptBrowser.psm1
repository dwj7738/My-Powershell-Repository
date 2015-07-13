#requires -Version 3

#Import Localized Data
Import-LocalizedData -BindingVariable Messages

# A variable that contains the install directory path of Script Browser and Script Analyzer.
if ($env:PROCESSOR_ARCHITECTURE -eq "X86")
{
    $installDir = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Script Browser\" -PSProperty "Install Directory" -ErrorAction:SilentlyContinue
}
else
{
    $installDir = Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Script Browser\" -PSProperty "Install Directory" -ErrorAction:SilentlyContinue
}

if ($installDir -ne $null)
{
    $installDir = $installDir.'Install Directory'
}
else
{
    $errorMsg = $Messages.MissingRegValue
    throw $errorMsg
}

# Adds Script Browser to Windows PowerShell ISE.
function Enable-ScriptBrowser
{
    # This function is only available in Windows PowerShell ISE console pane.
    TestWindowsPowerShellISE -FunctionName "Enable-ScriptBrowser"

    try
    {
        Add-Type -Path "$installDir\System.Windows.Interactivity.dll" -ErrorAction:Stop
        Add-Type -Path "$installDir\ScriptBrowser.dll" -ErrorAction:Stop
        $scriptBrowser = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add('Script Browser', [ScriptExplorer.Views.MainView], $true)
        $psISE.CurrentPowerShellTab.VisibleVerticalAddOnTools.SelectedAddOnTool = $scriptBrowser
    }
    catch
    {
        Write-Error -ErrorRecord $PSItem
    }
} # end Enable-ScriptBrowser.

# Removes Script Browser from Windows PowerShell ISE.
function Disable-ScriptBrowser
{
    # This function is only available in Windows PowerShell ISE console pane.
    TestWindowsPowerShellISE -FunctionName "Disable-ScriptBrowser"

    try
    {
        $scriptBrowser = $psISE.CurrentPowerShellTab.VerticalAddOnTools | `
            Where-Object -FilterScript {$PSItem.Control.ToString() -eq "ScriptExplorer.Views.MainView"}

        if ($scriptBrowser -ne $null)
        {
            [void]$psISE.CurrentPowerShellTab.VerticalAddOnTools.Remove($scriptBrowser)
        }
    }
    catch
    {
        Write-Error -ErrorRecord $PSItem
    }
} # end Disable-ScriptBrowser.

# Adds Script Analyzer to Windows PowerShell ISE.
function Enable-ScriptAnalyzer
{
    # This function is only available in Windows PowerShell ISE console pane.
    TestWindowsPowerShellISE -FunctionName "Enable-ScriptAnalyzer"

    try
    {
        Add-Type -Path "$installDir\System.Windows.Interactivity.dll" -ErrorAction:Stop
        Add-Type -Path "$installDir\BestPractices.dll" -ErrorAction:Stop
        $scriptAnalyzer = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add('Script Analyzer', [BestPractices.Views.BestPracticesView], $true)
        $psISE.CurrentPowerShellTab.VisibleVerticalAddOnTools.SelectedAddOnTool = $scriptAnalyzer
    }
    catch
    {
        Write-Error -ErrorRecord $PSItem
    }
} # end Enable-ScriptAnalyzer.

# Removes Script Analyzer from Windows PowerShell ISE.
function Disable-ScriptAnalyzer
{
    # This function is only available in Windows PowerShell ISE console pane.
    TestWindowsPowerShellISE -FunctionName "Disable-ScriptAnalyzer"

    try
    {
        $scriptAnalyzer = $psISE.CurrentPowerShellTab.VerticalAddOnTools | `
            Where-Object -FilterScript {$PSItem.Control.ToString() -eq "BestPractices.Views.BestPracticesView"}

        if ($scriptAnalyzer -ne $null)
        {
            [void]$psISE.CurrentPowerShellTab.VerticalAddOnTools.Remove($scriptAnalyzer)
        }
    }
    catch
    {
        Write-Error -ErrorRecord $PSItem
    }
} # end Disable-ScriptAnalyzer.

# Start Script Browser desktop application.
function Start-ScriptBrowserDesktop
{
    try
    {
        Start-Process -FilePath "$installDir\ScriptBrowserDesktop.exe" -ErrorAction:Stop
    }
    catch
    {
        Write-Error -ErrorRecord $PSItem
    }
} # end Start-ScriptBrowserApp.

#region Helper function(s)

# Some functions are only available in Windows PowerShell ISE console pane.
function TestWindowsPowerShellISE
{
    param ([string]$FunctionName)

    if ($Host.Name -ne "Windows PowerShell ISE Host")
    {
        $errorMsg = $Messages.RequiresISE -f $FunctionName
        throw $errorMsg
    }
}
#endregion

Export-ModuleMember -Function "Enable-ScriptBrowser", "Disable-ScriptBrowser", "Enable-ScriptAnalyzer", "Disable-ScriptAnalyzer", "Start-ScriptBrowserDesktop"