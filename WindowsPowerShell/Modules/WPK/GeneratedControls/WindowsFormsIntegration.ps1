function New-ElementHost {
    
    <#
    
    .Description
        Creates a new System.Windows.Forms.Integration.ElementHost
    .Synopsis
        Creates a new System.Windows.Forms.Integration.ElementHost
    .Example
        New-ElementHost
    .Example
        New-ElementHost -OutputXaml
    .Parameter OutputXaml
        If Set, will output the object as XAML instead of creating it
    #>

    
    
    param(
        
    [Switch]
    ${AutoSize},

    ${Child},

    [Switch]
    ${BackColorTransparent},

    [System.String]
    ${AccessibleDefaultActionDescription},

    [System.String]
    ${AccessibleDescription},

    [System.String]
    ${AccessibleName},

    [System.Windows.Forms.AccessibleRole]
    ${AccessibleRole},

    [Switch]
    ${AllowDrop},

    [System.Windows.Forms.AnchorStyles]
    ${Anchor},

    ${AutoScrollOffset},

    ${BackColor},

    ${BackgroundImage},

    [System.Windows.Forms.ImageLayout]
    ${BackgroundImageLayout},

    ${BindingContext},

    ${Bounds},

    [Switch]
    ${Capture},

    [Switch]
    ${CausesValidation},

    ${ClientSize},

    ${ContextMenu},

    ${ContextMenuStrip},

    ${Controls},

    ${Cursor},

    [System.Windows.Forms.DockStyle]
    ${Dock},

    [Switch]
    ${Enabled},

    ${Font},

    ${ForeColor},

    [System.Int32]
    ${Height},

    [Switch]
    ${IsAccessible},

    [System.Int32]
    ${Left},

    ${Location},

    ${Margin},

    ${MaximumSize},

    ${MinimumSize},

    [System.String]
    ${Name},

    ${Parent},

    ${Region},

    [System.Windows.Forms.RightToLeft]
    ${RightToLeft},

    ${Site},

    ${Size},

    [System.Int32]
    ${TabIndex},

    [Switch]
    ${TabStop},

    ${Tag},

    [System.String]
    ${Text},

    [System.Int32]
    ${Top},

    [Switch]
    ${UseWaitCursor},

    [Switch]
    ${Visible},

    [System.Int32]
    ${Width},

    ${WindowTarget},

    ${Padding},

    [System.Windows.Forms.ImeMode]
    ${ImeMode},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ChildChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BindingContextChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Click},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ClientSizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ControlAdded},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ControlRemoved},

    [System.Management.Automation.ScriptBlock[]]
    ${On_CursorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DoubleClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragDrop},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragOver},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Enter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_FontChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ForeColorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GiveFeedback},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Invalidated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyPress},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Layout},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Leave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseCaptureChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseDoubleClick},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseHover},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseWheel},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PaddingChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Paint},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewKeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryContinueDrag},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Resize},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RightToLeftChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TextChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_AutoSizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackColorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackgroundImageChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_BackgroundImageLayoutChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_CausesValidationChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuStripChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DockChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_EnabledChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LocationChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MarginChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RegionChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TabIndexChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TabStopChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_VisibleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HandleCreated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HandleDestroyed},

    [System.Management.Automation.ScriptBlock[]]
    ${On_HelpRequested},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryAccessibilityHelp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Move},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ChangeUICues},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StyleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SystemColorsChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Validating},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Validated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ParentChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ImeModeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Disposed},

    [Switch]
    ${OutputXaml}
    )
    begin {
        
    }
    process {
        
        try {
        $Object = New-Object System.Windows.Forms.Integration.ElementHost
        } catch {
            throw $_
            return
        } 
        Set-Property -property $psBoundParameters -inputObject $Object
        if ($outputXaml) {                
            $strWrite = New-Object IO.StringWriter
            ([xml]([Windows.Markup.XamlWriter]::Save($Object))).Save($strWrite)
            return "$strWrite"
        }
        $Object
    }
    end {
        
    }
} function New-PropertyMap {
    
    <#
    
    .Description
        Creates a new System.Windows.Forms.Integration.PropertyMap
    .Synopsis
        Creates a new System.Windows.Forms.Integration.PropertyMap
    .Example
        New-PropertyMap
    .Example
        New-PropertyMap -OutputXaml
    .Parameter OutputXaml
        If Set, will output the object as XAML instead of creating it
    #>

    
    
    param(
        
    ${Item},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PropertyMappingError},

    [Switch]
    ${OutputXaml}
    )
    begin {
        
    }
    process {
        
        try {
        $Object = New-Object System.Windows.Forms.Integration.PropertyMap
        } catch {
            throw $_
            return
        } 
        Set-Property -property $psBoundParameters -inputObject $Object
        if ($outputXaml) {                
            $strWrite = New-Object IO.StringWriter
            ([xml]([Windows.Markup.XamlWriter]::Save($Object))).Save($strWrite)
            return "$strWrite"
        }
        $Object
    }
    end {
        
    }
} function New-WindowsFormsHost {
    
    <#
    
    .Description
        Creates a new System.Windows.Forms.Integration.WindowsFormsHost
    .Synopsis
        Creates a new System.Windows.Forms.Integration.WindowsFormsHost
    .Example
        New-WindowsFormsHost
    .Example
        New-WindowsFormsHost -OutputXaml
    .Example
        New-WindowsFormsHost -Show
    .Example
        New-WindowsFormsHost -AsJob
    .Parameter Show
        
    If Set, will show the visual in a new window
    
    .Parameter OutputXaml
        If Set, will output the object as XAML instead of creating it
    .Parameter AsJob
        
    If Set, will show the visual in a background WPF Job
    
    .Parameter Resource
        
    A Dictionary of Resources.  Use this dictionary to store information that 
    the rest of the user interface needs to access.
    
    #>

    
    
    param(
        
    ${Child},

    ${Padding},

    [System.Int32]
    ${TabIndex},

    ${FontFamily},

    [System.Double]
    ${FontSize},

    ${FontStyle},

    ${FontWeight},

    ${Foreground},

    ${Background},

    ${Style},

    [Switch]
    ${OverridesDefaultStyle},

    ${Triggers},

    ${DataContext},

    ${BindingGroup},

    ${Language},

    [System.String]
    ${Name},

    ${Tag},

    ${InputScope},

    ${LayoutTransform},

    [System.Double]
    ${Width},

    [System.Double]
    ${MinWidth},

    [System.Double]
    ${MaxWidth},

    [System.Double]
    ${Height},

    [System.Double]
    ${MinHeight},

    [System.Double]
    ${MaxHeight},

    [System.Windows.FlowDirection]
    ${FlowDirection},

    ${Margin},

    [System.Windows.HorizontalAlignment]
    ${HorizontalAlignment},

    [System.Windows.VerticalAlignment]
    ${VerticalAlignment},

    ${FocusVisualStyle},

    ${Cursor},

    [Switch]
    ${ForceCursor},

    ${ToolTip},

    ${ContextMenu},

    ${InputBindings},

    ${CommandBindings},

    [Switch]
    ${AllowDrop},

    ${RenderSize},

    ${RenderTransform},

    ${RenderTransformOrigin},

    [System.Double]
    ${Opacity},

    ${OpacityMask},

    ${BitmapEffect},

    ${Effect},

    ${BitmapEffectInput},

    [System.String]
    ${Uid},

    [System.Windows.Visibility]
    ${Visibility},

    [Switch]
    ${ClipToBounds},

    ${Clip},

    [Switch]
    ${SnapsToDevicePixels},

    [Switch]
    ${IsEnabled},

    [Switch]
    ${IsHitTestVisible},

    [Switch]
    ${Focusable},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LayoutError},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ChildChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MessageHook},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TargetUpdated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SourceUpdated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DataContextChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_RequestBringIntoView},

    [System.Management.Automation.ScriptBlock[]]
    ${On_SizeChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Initialized},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Loaded},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Unloaded},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ToolTipOpening},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ToolTipClosing},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuOpening},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ContextMenuClosing},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseLeftButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseLeftButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseLeftButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseLeftButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseRightButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseRightButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseRightButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseRightButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewMouseWheel},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseWheel},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_MouseLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotMouseCapture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostMouseCapture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryCursor},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusInAirMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusInAirMove},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusInRange},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusInRange},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusOutOfRange},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusOutOfRange},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusSystemGesture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusSystemGesture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotStylusCapture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostStylusCapture},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_StylusButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusButtonDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewStylusButtonUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewKeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyDown},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewKeyUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_KeyUp},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewGotKeyboardFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotKeyboardFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewLostKeyboardFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostKeyboardFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewTextInput},

    [System.Management.Automation.ScriptBlock[]]
    ${On_TextInput},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewQueryContinueDrag},

    [System.Management.Automation.ScriptBlock[]]
    ${On_QueryContinueDrag},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewGiveFeedback},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GiveFeedback},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewDragEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragEnter},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewDragOver},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragOver},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewDragLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DragLeave},

    [System.Management.Automation.ScriptBlock[]]
    ${On_PreviewDrop},

    [System.Management.Automation.ScriptBlock[]]
    ${On_Drop},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsMouseDirectlyOverChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsKeyboardFocusWithinChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsMouseCapturedChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsMouseCaptureWithinChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsStylusDirectlyOverChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsStylusCapturedChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsStylusCaptureWithinChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsKeyboardFocusedChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LayoutUpdated},

    [System.Management.Automation.ScriptBlock[]]
    ${On_GotFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_LostFocus},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsEnabledChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsHitTestVisibleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_IsVisibleChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_FocusableChanged},

    [Switch]
    ${OutputXaml},

    [System.Collections.Hashtable]
    ${Resource},

    [System.Collections.Hashtable]
    ${DataBinding},

    [System.Collections.Hashtable]
    ${RoutedEvent},

    [System.Collections.Hashtable]
    ${DependencyProperty},

    [Switch]
    ${Show},

    [System.Int32]
    ${Row},

    [System.Int32]
    ${Column},

    [System.Int32]
    ${RowSpan},

    [System.Int32]
    ${ColumnSpan},

    [System.Int32]
    ${ZIndex},

    [System.Windows.Controls.Dock]
    ${Dock},

    [System.Double]
    ${Top},

    [System.Double]
    ${Left},

    [Switch]
    ${AsJob}
    )
    begin {
        
    }
    process {
        
        if ($PSBoundParameters.ContainsKey("AsJob")) {
            $null = $psBoundParameters.Remove("AsJob")
            $ScriptBlock = $MyInvocation.MyCommand.ScriptBlock
            $Command = $MyInvocation.InvocationName
            if (-not $Command) {
                $Command = "Start-WPFJob"
            }
            $Parameters = $PSBoundParameters
            $AdditionalContext = @(Get-PSCallstack)[1].InvocationInfo.MyCommand.Definition
            if (-not $AdditionalContext) { $AdditionalContext += {} }
            if ($AdditionalContext -like "*.ps1") { 
                $AdditionalContext = [ScriptBlock]::Create(
                    [IO.File]::ReadAllText($AdditionalContext)
                )
            } else {
                $AdditionalContext = [ScriptBlock]::Create($AdditionalContext)
            }

            
            $JobParameters = @{
                ScriptBlock = $MyInvocation.MyCommand.ScriptBlock
                Command = $Command
                AdditionalContext = $AdditionalContext
                Name = $Name
            }
            
            if (-not $JobParameters.Name) {
                $JobParameters.Name = $MyInvocation.InvocationName
            }

            if ($Parameters) {
                Start-WPFJob @JobParameters -Parameter $Parameters         
            } else {
                Start-WPFJob @JobParameters
            }
            return
        }
        try {
        $Object = New-Object System.Windows.Forms.Integration.WindowsFormsHost
        } catch {
            throw $_
            return
        } 
        if ($PSBoundParameters.ContainsKey("Left")) {            
            $object.SetValue([Windows.Controls.Canvas]::LeftProperty, $Left)
            $Null = $PSBoundParameters.Remove("Left")
        }
        if ($PSBoundParameters.ContainsKey("Top")) {            
            $object.SetValue([Windows.Controls.Canvas]::TopProperty, $top)
            $Null = $PSBoundParameters.Remove("Top")
        }
        if ($PSBoundParameters.ContainsKey("Row")) {
            $Object.SetValue([Windows.Controls.Grid]::RowProperty, $row)
            $Null = $PSBoundParameters.Remove("Row")
        }
        if ($PSBoundParameters.ContainsKey("Column")) {
            $Object.SetValue([Windows.Controls.Grid]::ColumnProperty, $column)
            $Null = $PSBoundParameters.Remove("Column")
        }
        if ($PSBoundParameters.ContainsKey("RowSpan")) {
            $Object.SetValue([Windows.Controls.Grid]::RowSpanProperty, $rowSpan)
            $Null = $PSBoundParameters.Remove("RowSpan")
        }
        if ($PSBoundParameters.ContainsKey("ColumnSpan")) {
            $Object.SetValue([Windows.Controls.Grid]::ColumnSpanProperty, $columnSpan)
            $Null = $PSBoundParameters.Remove("ColumnSpan")
        }
        if ($PSBoundParameters.ContainsKey("ZIndex")) {
            $Object.SetValue([Windows.Controls.Panel]::ZIndexProperty, $ZIndex)
            $Null = $PSBoundParameters.Remove("ZIndex")
        }
        if ($PSBoundParameters.ContainsKey("Dock")) {
            $Object.SetValue([Windows.Controls.DockPanel]::DockProperty, $Dock)
            $Null = $PSBoundParameters.Remove("Dock")
        }
        $null = $psBoundParameters.Remove("Show")
        if ($PsBoundParameters.ContainsKey("DependencyProperty")) {
            $null = $PsBoundParameters.Remove("DependencyProperty")
            foreach ($dp in $dependencyProperty.GetEnumerator()) {
                if ($dp.Key -is [Windows.DependencyProperty]) {
                    $Null = $Object.SetValue($dp.Key, $dp.Value)
                } else {
                    $Prop = $Object.GetType()::"$($dp.Key)Property"
                    if ($Prop) {
                        $null = $Object.SetValue(
                            $Prop,
                            $dp.Value -as $Prop.PropertyType
                        ) 
                    }
                }
            }
        }
        if ($PsBoundParameters.ContainsKey("RoutedEvent")) {
            $null = $PsBoundParameters.Remove("RoutedEvent")
            foreach ($re in $RoutedEvent.GetEnumerator()) {
                if ($re.Key -is [Windows.RoutedEvent]) {
                    $Null = $Object.SetValue($re.Key, $re.Value)
                } else {
                    $Event = $object.GetType()::"$($re.Key)Event"
                    if ($Event) {
                        $null = $Object.AddHandler(
                            $Event,
                            $re.Value -as $Event.HandlerType
                        ) 
                    }
                }
            }
        }
    $Object.Resources.Timers = 
        New-Object Collections.Generic.Dictionary["string,Windows.Threading.DispatcherTimer"]
    $Object.Resources.TemporaryControls = @{}
    $Object.Resources.Scripts =
        New-Object Collections.Generic.Dictionary["string,ScriptBlock"]
    
        if ($psBoundParameters.ContainsKey("DataBinding")) {
            $null = $psBoundParameters.Remove("DataBinding")
            foreach ($db in $DataBinding.GetEnumerator()) {
                if ($db.Key -is [Windows.DependencyProperty]) {
                    $Null = $Object.SetBinding($db.Key, $db.Value)
                } else {
                    $Prop = $Object.GetType()::"$($db.Key)Property"
                    if ($Prop) {
                        Write-Debug (
                        $Object.SetBinding(
                            $Prop,
                            $db.Value) | Out-String
                        ) 
                    }
                }
            }
        }
        if ($psBoundParameters.ContainsKey("Resource")) {
            foreach ($kv in $resource.GetEnumerator())
            {
                $null = $object.Resources.Add($kv.Key, $kv.Value)
            }            
            $null=$psBoundParameters.Remove("Resource")
        }
        Set-Property -property $psBoundParameters -inputObject $Object
        if ($outputXaml) {                
            $strWrite = New-Object IO.StringWriter
            ([xml]([Windows.Markup.XamlWriter]::Save($Object))).Save($strWrite)
            return "$strWrite"
        }
        if ($show) {
            return Show-Window $Object 
        }
        $Object
    }
    end {
        
    }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoBU4eTkWfUcfq3k9BxAHdhCx
# oLegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGRI2LUdXme0M+JL
# wm637PwF0fQmMA0GCSqGSIb3DQEBAQUABIIBADefHesLVvjhFt65KYRRFtsz7vuI
# OaYJbUAbYwQRuVljlGrow54bKFSe65z/gn8L9n1lNN7un7HXnsmVrwyREFDkLJsV
# xOPh7V5kVvjd9ZnvcrqaDTTBkaS1ym6uUtwy5FxYInaO7LSKGTCkB7HYAXO60X7S
# /odDhfDbxm1XwUDhTbjAiKNO2GE44FdIuDhVcUeN/ZfR0mVe2w2TMBRkHo/f0YOr
# KRcrQxm9XaiB4RRCY05iWud+Pa+VIxBTCqGvzvPdiF8lIkpcZk5PInGWh9TMXZnT
# D+hE6/6L0sOp3ZCGTLYkv1HsKgL7VJ6rT0J19E3glM3rZGrWaBBhjvfopSo=
# SIG # End signature block
