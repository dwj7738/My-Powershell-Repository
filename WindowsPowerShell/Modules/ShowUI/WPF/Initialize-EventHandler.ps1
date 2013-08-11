function Initialize-EventHandler
{
    param(
        $resource = $(try { Get-Resource -ErrorAction SilentlyContinue } catch { Write-Debug "$_" }),
        $parent = $(try { Get-ParentControl -ErrorAction SilentlyContinue } catch { Write-Debug "$_" })
    )
    if ($parent) { 
        
        $namedControls = Get-ChildControl -OutputNamedControl -Control $parent 
        
        if ($namedControls) { 
            foreach ($nc in $namedControls.GetEnumerator()) {                
                if ($nc.Key -and $nc.Value) {
                    . ([ScriptBlock]::create("`${Global:$($nc.Key)} = `$nc.Value"))
                }
                    
                
                # Set-Variable -Name $nc.Key -Value $nc.Value -Scope 0 -Force -Option AllScope                        
            }
        }
        if ($parent.Name) { 
            . ([ScriptBlock]::create("`${Global:$($parent.Name)} = `$parent"))
            
        }
        if ($parent.GetValue -and
            $($controlname = $parent.GetValue([ShowUI.ShowUISetting]::ControlNameProperty);$controlName))
        {
            
            . ([ScriptBlock]::create("`${Global:$($controlname)} = `$parent"))
        }
        
    } else {
        
    }
    
    if ($resource) {    
        foreach ($nc in $resource.GetEnumerator()) {
            if ($nc.Key -and 
                'Scripts', 'Timers', 'EventHandlers' -notcontains $nc.Key) {
                if ($nc.Value -is [ScriptBlock]) {
                    $lines = $nc.Value.ToString().Split([Environment]::NewLine, [StringSplitOptions]'RemoveEmptyEntries')
                    if ($lines[0,1] -like "*function*") {
                        $null = New-Module -ScriptBlock $nc.Value
                        continue
                    }
                }

                . ([ScriptBlock]::create("`${Global:$($nc.Key)} = `$nc.Value"))                
            }        
        }
    }
}
