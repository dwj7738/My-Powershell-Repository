@{
    Name = 'Find'
    Screen = {
        New-Border -ControlName FindInFiles -BorderBrush Black -CornerRadius 5 -Child {
            New-grid -rows ((@('Auto') * 9) + '1*') -children {
                New-TextBlock "Find in Files"  -FontSize 19 -FontFamily 'Segoe UI' -Row 0 -Margin 3 -FontWeight DemiBold
                
                New-StackPanel -Row 1 -Children {
                    New-Grid -Columns 2 -Children {
                        New-TextBlock -Text "Keyword" -FontFamily 'Segoe UI' -Row 2 -Margin 5 -FontSize 14 
                        New-CheckBox -horizontalalignment right  -Name IsRegex -Content "Regular E_xpression" -FontFamily 'Segoe UI'  -FontSize 14 -Column 1 
                    }
                    New-TextBox -Name "Keyword" -Row 3  -Margin 5 -On_TextChanged {
                        $nc = $this.Parent.Parent | 
                                Get-childControl -OutputNamedControl
                        $nc.FindButton.IsEnabled = $this.Text -as [bool]
                    }
                }
                
                
                
                
                New-CheckBox -Row 4 -Margin 5 -Name InLoadedFiles -Content "Find in Loaded Files" -ToolTip "Finds within currently loaded files" -IsChecked $true
                New-CheckBox -Row 5 -Margin 5 -Name InLoadedDirectories -Content "Find in Loaded _Directories" -ToolTip "Finds within the directories of open files"
                New-CheckBox -Row 6 -Margin 5 -Name InModules -Content "Find in _Modules" -ToolTip "Finds beneath different system wide module locations"
                New-CheckBox -Row 7 -Margin 5 -Name InPowerShell -Content "Find in _PowerShell" -ToolTip "Finds beneath MyDocuments\WindowsPowerShell"

                                
                
                New-Button -Row 8 -Name FindButton -Content "F_ind"  -FontFamily 'Segoe UI' -FontSize 19 -FontWeight DemiBold -On_Click {
                    $nc = $this.Parent | 
                            Get-childControl -OutputNamedControl

                    $keyword = $nc.Keyword.Text

                    
                    

                    $options = @{
                        Keyword = $keyword
                        SimpleMatch = $true
                    }


                    if ($nc.InLoadedFiles.IsChecked) {
                        $options.FindInLoadedFiles = $true
                        #
                    } 
                    if ($nc.InLoadedDirectories.IsChecked) {
                        $options.FindInLoadedDirs = $true
                        #$filesList  += $nc.OpenedFilesList.ItemsSource | Split-Path | Select-Object -Unique
                    }
                    
                    if ($nc.InModules.IsChecked) {
                        $options.FindInModules= $true
                        #$filesList  += $nc
                    }

                    if ($nc.InPowerShell.IsChecked) {
                        $options.FindInPSDir= $true
                        #$filesList  += $nc.PSDir 
                    }

                    if ($nc.IsRegex.IsChecked) {
                        $options.SimpleMatch = $false
                    }

                    

                    $mainRunspace = [Windows.Window]::GetWindow($this).Resources["MainRunspace"]
                    if ($rs.RunspaceAvailability -ne 'Busy') {
                        #$mainRunspace.sessionStateProxy.SetVariable("FileList", $filesList)
                        $mainRunspace.sessionStateProxy.SetVariable("FindOptions", $Options)
                        
                        $ise = [Windows.Window]::GetWindow($this).Resources["ISE"]

                        $findScript = {
                            param([Hashtable]$FindOptions)
                            
                            $filesList = @()
                            if ($FindOptions.FindInPSDir) {
                                $filesList += Get-ChildItem $home\Documents\WindowsPowerShell -Recurse
                            }
                            if ($findOptions.FindInLoadedFiles) {
                                
                                $filesList  += $psise.CurrentPowerShellTab.Files | 
                                    ForEach-Object { $_.FullPath } 
                            }
                            if ($findOptions.FindInLoadedDirs) {
                                $filesList  += $psise.CurrentPowerShellTab.Files | 
                                    ForEach-Object { $_.FullPath } | 
                                    Split-Path | 
                                    Select-Object -Unique
                            }   
                            if ($findOptions.FindInModules) {
                                $filesList += $env:PSModulePath -split ';' | 
                                    Get-ChildItem |
                                    Get-ChildItem |
                                    Get-ChildItem
                            }
                            
                            $filesList | Dir | Select-String $FindOptions.Keyword -SimpleMatch:$($findOptions.SimpleMatch)
                        }
                        $mainRunspace.sessionStateProxy.SetVariable("FindScript", $findScript)

                        $ise.currentPowerShellTab.Invoke({. ([ScriptBLock]::Create($findScript)) $FindOptions})
                    }
                    
                    
                    
                }

                #New-ListBox -Row 9 -Name FoundFiles 



                New-ListBox -Visibility Collapsed -Name OpenedFilesList
                New-TextBox -Visibility Collapsed -Name CurrentDir
                New-TextBox -Visibility Collapsed -Name PSDir
                New-ListBox -Visibility Collapsed -Name ModuleDirList

            }
        }
    }
    DataUpdate = {
        New-Object PSObject -Property @{
            OpenedFiles = @($psise.CurrentPowerShellTab.Files | ForEach-Object { $_.FullPath })
            CurrentDir = "$pwd"
            ModulePaths =@($Env:psmodulePath -split ';')
            PowerShellDir = "$home\Documents\WindowsPowerShell"
        }
        
        
    } 
    UiUpdate = {
        $hi = $Args

        
        
        $nc = $this.Content | 
            Get-ChildControl -OutputNamedControl 
        
        $nc.OpenedFilesList.itemssource = @($hi.OpenedFiles)
        $nc.ModuleDirList.itemssource = @($hi.ModulePaths)
        $nc.CurrentDir.Text = @($hi.CurrentDir)
        $nc.PSDir.Text = @($hi.PowerShellDir)


        $this.Content.Resources.Ise = $this.Parent.HostObject
    }
    UpdateFrequency = "0:0:10"
    ShortcutKey = "Ctrl + Shift + F"
} 
