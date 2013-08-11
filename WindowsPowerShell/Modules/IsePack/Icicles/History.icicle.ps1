@{
    Name = 'History'
    Screen = {
        New-Border -ControlName History -BorderBrush Black -CornerRadius 5 -Child {
            New-grid -rows 1*, auto -children {
                
                    New-ListBox -Row 0 -On_PreviewKeyDown {
                        if ($_.Key -eq 'Enter' -and $this.SelectedItem) {
                            . $this.Resources.'Select-ListItem' # When the user double clicks, go to the location and close the window
                            $_.Handled = $true
                        }
                    } -Name HistoryList -DisplayMemberPath CommandLine -On_MouseDoubleClick {
                        if ($this.SelectedItem) {
                            $ise = [Windows.Window]::GetWindow($this).Resources.ISE
                            $ise.CurrentPowerShellTab.Invoke($this.SelectedItem.CommandLine)                        
                        }
                        
                    } -On_SelectionChanged {
                        $nc = $this.Parent | 
                            Get-childControl -OutputNamedControl

                        if ($this.SelectedItem) {
                            $nc.StartTime.Content = 
                                $this.SelectedItem.StartExecutionTime.ToShortTimeString()
                            $nc.StopTime.Content = 
                                $this.SelectedItem.EndExecutionTime.ToShortTimeString()
                            $nc.Duration.Content  =  
                                $this.SelectedItem.EndExecutionTime - $this.SelectedItem.StartExecutionTime
                            $nc.CopyToClipboard.Tag = $this.SelectedItem.CommandLine
                            $nc.historyDetail.Visibility = "Visible"
                            

                        } else {
                           $nc.historyDetail.Visibility = "Collapsed"
                        }
                        
                    }


                    New-Grid -Row 1 -Name historyDetail -Rows 'Auto', 'Auto', 'Auto', 'Auto' -Columns 2 -Children {
                        New-Label -Content "Started" -Row 0 -HorizontalAlignment Right 
                        New-Label -Name StartTime 0 -Column 1 
                        New-Label -Content "Stopped" -Row 1 -HorizontalAlignment Right 
                        New-Label -Name StopTime -Column 1 -Row 1 
                        New-Label -Content "Duration" -Row 2 -HorizontalAlignment Right 
                        New-Label -Name Duration -Column 1  -Row 2 
                        New-Button -Row 3 -ColumnSpan 2 -Margin 3 -Padding 3 -Name CopyToClipboard -content "Copy To Clipboard"-HorizontalAlignment Center -FontFamily 'Segoe UI' -FontSize 19 -FontWeight DemiBold -On_Click {
                            [Windows.Clipboard]::SetText($this.tag)
                        }
                    }
                
            }
        }
    }
    DataUpdate = {
        Get-History | Sort-Object StartExecutionTime -Descending
        
    } 
    UiUpdate = {
        $hi = $Args

        
        
        $this.Content | 
            Get-ChildControl -ByName HistoryList | 
            ForEach-Object {  
                $_.Tag = $this.Parent.HostObject
                $_.itemssource = @($hi )
            }
        $this.Content.Resources.Ise = $this.Parent.HostObject
    }
    UpdateFrequency = "0:0:11"
    ShortcutKey = "Ctrl + Alt + H"
} 
