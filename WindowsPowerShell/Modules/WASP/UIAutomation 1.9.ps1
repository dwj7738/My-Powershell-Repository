## UI Automation v 1.8 -- REQUIRES the Reflection module (current version: http://poshcode.org/3174 )
## 
# WASP 2.0 is getting closer, but this is still just a preview:
# -- a lot of the commands have weird names still because they're being generated ignorantly
# -- eg: Invoke-Toggle.Toggle and  Invoke-Invoke.Invoke

# v 1.7 - Fixes using multiple checks like: Select-UIElement Red: Edit
# v 1.8 - Fixes .Net version problems: specifying CSharpVersion3 when in PowerShell 2
# v 1.9 - Fix bug with Select-UIElement by processName / processId

# IF your PowerShell is running in .Net 4
if($PSVersionTable.CLRVersion -gt "4.0") {
    $Language = "CSharp" # Version 4
    Add-Type -AssemblyName "UIAutomationClient, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
    Add-Type -AssemblyName "UIAutomationTypes, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
} else {
    # In PowerShell 2, we need to use the .Net 3 version
    $Language = "CSharpVersion3" 
    Add-Type -AssemblyName "UIAutomationClient, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
    Add-Type -AssemblyName "UIAutomationTypes, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
}


$SWA = "System.Windows.Automation"
#  Add-Accelerator InvokePattern      "$SWA.InvokePattern"                -EA SilentlyContinue
#  Add-Accelerator ExpandPattern      "$SWA.ExpandCollapsePattern"        -EA SilentlyContinue
#  Add-Accelerator WindowPattern      "$SWA.WindowPattern"                -EA SilentlyContinue
#  Add-Accelerator TransformPattern   "$SWA.TransformPattern"             -EA SilentlyContinue
#  Add-Accelerator ValuePattern       "$SWA.ValuePattern"                 -EA SilentlyContinue
#  Add-Accelerator TextPattern        "$SWA.TextPattern"                  -EA SilentlyContinue

# This is what requires the Reflection module:
Add-Accelerator Automation         "$SWA.Automation"                   -EA SilentlyContinue
Add-Accelerator AutomationElement  "$SWA.AutomationElement"            -EA SilentlyContinue
Add-Accelerator TextRange          "$SWA.Text.TextPatternRange"        -EA SilentlyContinue
#####  Conditions
Add-Accelerator Condition          "$SWA.Condition"                    -EA SilentlyContinue
Add-Accelerator AndCondition       "$SWA.AndCondition"                 -EA SilentlyContinue
Add-Accelerator OrCondition        "$SWA.OrCondition"                  -EA SilentlyContinue
Add-Accelerator NotCondition       "$SWA.NotCondition"                 -EA SilentlyContinue
Add-Accelerator PropertyCondition  "$SWA.PropertyCondition"            -EA SilentlyContinue
#####  IDentifiers
Add-Accelerator AutoElementIds     "$SWA.AutomationElementIdentifiers" -EA SilentlyContinue
Add-Accelerator TransformIds       "$SWA.TransformPatternIdentifiers"  -EA SilentlyContinue

##### Patterns:
$patterns = Get-Type -Assembly UIAutomationClient -Base System.Windows.Automation.BasePattern 
            #| Where { $_ -ne [System.Windows.Automation.InvokePattern] }


Add-Type -Language $Language -ReferencedAssemblies UIAutomationClient, UIAutomationTypes -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Windows.Automation;
using System.Runtime.InteropServices;


[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
public class StaticFieldAttribute : ArgumentTransformationAttribute {
   private Type _class;

   public override string ToString() {
      return string.Format("[StaticField(OfClass='{0}')]", OfClass.FullName);
   }

   public override Object Transform( EngineIntrinsics engineIntrinsics, Object inputData) {
      if(inputData is string && !string.IsNullOrEmpty(inputData as string)) {
         System.Reflection.FieldInfo field = _class.GetField(inputData as string, BindingFlags.Static | BindingFlags.Public);
         if(field != null) {
            return field.GetValue(null);
         }
      }
      return inputData;
   }
   
   public StaticFieldAttribute( Type ofClass ) {
      OfClass = ofClass;
   }

   public Type OfClass {
      get { return _class; }
      set { _class = value; }
   }   
}

public static class UIAutomationHelper {

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern IntPtr FindWindow (string lpClassName, string lpWindowName);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern bool AttachThreadInput (int idAttach, int idAttachTo, bool fAttach);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern int GetWindowThreadProcessId (IntPtr hWnd, IntPtr lpdwProcessId);

   [DllImport ("user32.dll", CharSet = CharSet.Auto)]
   static extern IntPtr SetForegroundWindow (IntPtr hWnd);

   public static AutomationElement RootElement {
      get { return AutomationElement.RootElement; }
   }


   ///<synopsis>Using Win32 to set foreground window because AutomationElement.SetFocus() is unreliable</synopsis>
   public static bool SetForeground(this AutomationElement element)
   {
      if(element == null) { 
         throw new ArgumentNullException("element");
      }

      // Get handle to the element
      IntPtr other = FindWindow (null, element.Current.Name);

      // // Get the Process ID for the element we are trying to
      // // set as the foreground element
      // int other_id = GetWindowThreadProcessId (other, IntPtr.Zero);
      // 
      // // Get the Process ID for the current process
      // int this_id = GetWindowThreadProcessId (Process.GetCurrentProcess().Handle, IntPtr.Zero);
      // 
      // // Attach the current process's input to that of the 
      // // given element. We have to do this otherwise the
      // // WM_SETFOCUS message will be ignored by the element.
      // bool success = AttachThreadInput(this_id, other_id, true);

      // Make the Win32 call
      IntPtr previous = SetForegroundWindow(other);

      return !IntPtr.Zero.Equals(previous);
   }
}
"@
            
## TODO: Write Get-SupportedPatterns or rather ... 
## Get-SupportedFunctions (to return the names of the functions for the supported patterns)
## TODO: Support all the "Properties" too
## TODO: Figure out why Notepad doesn't support SetValue
## TODO: Figure out where the menus support went
ForEach($pattern in $patterns){
   $pattern | Add-Accelerator
   $PatternFullName = $pattern.FullName
   $PatternName = $Pattern.Name -Replace "Pattern","."
   $newline = "`n`t`t"
   
   New-Item "Function:ConvertTo-$($Pattern.Name)" -Value "
   param(
      [Parameter(ValueFromPipeline=`$true)][Alias('Element','AutomationElement')][AutomationElement]`$InputObject
   )
   process { 
      trap { 
         if(`$_.Exception.Message -like '*Unsupported Pattern.*') {
            Write-Error `"Cannot get ```"$($Pattern.Name)```" from that AutomationElement, `$(`$_)` You should try one of: `$(`$InputObject.GetSupportedPatterns()|%{```"'```" + (`$_.ProgrammaticName.Replace(```"PatternIdentifiers.Pattern```",```"```")) + ```"Pattern'```"})`"; continue;
         }
      }
      Write-Output `$InputObject.GetCurrentPattern([$PatternFullName]::Pattern).Current
   }"
   
   $pattern.GetMethods() | 
   Where { $_.DeclaringType -eq $_.ReflectedType -and !$_.IsSpecialName } | 
   ForEach {
      $FunctionName = "Function:Invoke-$PatternName$($_.Name)"
      $Position = 1
      
      if (test-path $FunctionName) { remove-item $FunctionName }
      $Parameters = @("$newline[Parameter(ValueFromPipeline=`$true)]"+
                      "$newline[Alias('Parent','Element','Root','AutomationElement')]"+
                      "$newline[AutomationElement]`$InputObject"
                      ) + 
                    @(
                      "[Parameter()]$newline[Switch]`$Passthru"
                     ) + 
                    @($_.GetParameters() | % { "[Parameter(Position=$($Position; $Position++))]$newline[$($_.ParameterType.FullName)]`$$($_.Name)" })
      $Parameters = $Parameters -Join "$newline,$newline"
      $ParameterValues = '$' + (@($_.GetParameters() | Select-Object -Expand Name ) -Join ', $')

      $definition = @"
   param(
      $Parameters
   )
   process { 
      ## trap { Write-Warning "`$(`$_)"; break }
      `$pattern = `$InputObject.GetCurrentPattern([$PatternFullName]::Pattern)
      if(`$pattern) {
         `$Pattern.$($_.Name)($(if($ParameterValues.Length -gt 1){ $ParameterValues }))
      }
      if(`$passthru) {
         `$InputObject
      }
   }
"@
      
      trap {
         Write-Warning $_
         Write-Host $definition -fore cyan
      }
      New-Item $FunctionName -value $definition
   }
   
   $pattern.GetProperties() | 
   Where { $_.DeclaringType -eq $_.ReflectedType -and $_.Name -notmatch "Cached|Current"} |
   ForEach {
      $FunctionName = "Function:Get-$PatternName$($_.Name)".Trim('.')
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      )      
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         `$pattern = `$AutomationElement.GetCurrentPattern([$PatternFullName]::Pattern)
         if(`$pattern) {
            `$pattern.'$($_.Name)'
         }
      }"
   }
   ## So far this seems to be restricted to Text (DocumentRange) elements
   $pattern.GetFields() |
   Where { $_.FieldType.Name -like "*TextAttribute"} |
   ForEach {
      $FunctionName = "Function:Get-Text$($_.Name -replace 'Attribute')"
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      )
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         `$AutomationElement.GetAttributeValue([$PatternFullName]::$($_.Name))
      }"
   }
   
   $pattern.GetFields() | Where { $_.FieldType -eq [System.Windows.Automation.AutomationEvent] } |
   ForEach {
      $Name = $_.Name -replace 'Event$'
      $FunctionName = "Function:Register-$($PatternName.Trim('.'))$Name"
      if (test-path $FunctionName) { remove-item $FunctionName }
      New-Item $FunctionName -value "
      param(
         [Parameter(ValueFromPipeline=`$true)]
         [AutomationElement]`$AutomationElement
      ,
         [System.Windows.Automation.TreeScope]`$TreeScope = 'Element'
      ,
         [ScriptBlock]`$EventHandler
      )
      process { 
         trap { Write-Warning `"$PatternFullName `$_`"; continue }
         [Automation]::AddAutomationEventHandler( [$PatternFullName]::$Name, `$AutomationElement, `$TreeScope, `$EventHandler )
      }"
   }
}

$FalseCondition = [Condition]::FalseCondition
$TrueCondition  = [Condition]::TrueCondition

Add-Type -AssemblyName System.Windows.Forms
Add-Accelerator SendKeys           System.Windows.Forms.SendKeys       -EA SilentlyContinue

$AutomationProperties = [system.windows.automation.automationelement+automationelementinformation].GetProperties()

Set-Alias Invoke-UIElement Invoke-Invoke.Invoke

function formatter  { END {
   $input | Format-Table @{l="Text";e={$_.Text.SubString(0,25)}}, ClassName, FrameworkId -Auto
}}

function Get-ClickablePoint {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
)
   process {
      $InputObject.GetClickablePoint()
   }
}

function Show-Window {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      Set-UIFocus $InputObject
      if($passthru) {
         $InputObject
      }        
   }
}

function Set-UIFocus {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      try {
         [UIAutomationHelper]::SetForeground( $InputObject )
         $InputObject.SetFocus()
      } catch {
         Write-Verbose "SetFocus fail, trying SetForeground"
      }
      if($passthru) {
         $InputObject
      }        
   }
}

function Send-UIKeys {
[CmdletBinding()]
param(
   [Parameter(Position=0)]
   [string]$Keys
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru
,
   [Parameter()]
   [Switch]$Async
)
   process {
      if(!$InputObject.Current.IsEnabled)
      {
         Write-Warning "The Control is not enabled!"
      }
      if(!$InputObject.Current.IsKeyboardFocusable)
      {
         Write-Warning "The Control is not focusable!"
      }
      Set-UIFocus $InputObject
      
      if($Async) {
         [SendKeys]::Send( $Keys )
      } else {
         [SendKeys]::SendWait( $Keys )
      }
      
      if($passthru) {
         $InputObject
      }      
   }
}

function Set-UIText {
[CmdletBinding()]
param(
   [Parameter(Position=0)]
   [string]$Text
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("Parent","Element","Root")]
   [AutomationElement]$InputObject
,
   [Parameter()]
   [Switch]$Passthru   
)
   process {
      if(!$InputObject.Current.IsEnabled)
      {
         Write-Warning "The Control is not enabled!"
      }
      if(!$InputObject.Current.IsKeyboardFocusable)
      {
         Write-Warning "The Control is not focusable!"
      }
      
      $valuePattern = $null
      if($InputObject.TryGetCurrentPattern([ValuePattern]::Pattern,[ref]$valuePattern)) {
         Write-Verbose "Set via ValuePattern!"
         $valuePattern.SetValue( $Text )
      } 
      elseif($InputObject.Current.IsKeyboardFocusable) 
      {
         Set-UIFocus $InputObject
         [SendKeys]::SendWait("^{HOME}");
         [SendKeys]::SendWait("^+{END}");
         [SendKeys]::SendWait("{DEL}");
         [SendKeys]::SendWait( $Text )
      }
      if($passthru) {
         $InputObject
      }      
   }
}

function Select-UIElement {
[CmdletBinding(DefaultParameterSetName="FromParent")]
PARAM (
   [Parameter(ParameterSetName="FromWindowHandle", Position="0", Mandatory=$true)] 
   [Alias("MainWindowHandle","hWnd","Handle","Wh")]
   [IntPtr[]]$WindowHandle=[IntPtr]::Zero
,
   [Parameter(ParameterSetName="FromPoint", Position="0", Mandatory=$true)]
   [System.Windows.Point[]]$Point
,
   [Parameter(ParameterSetName="FromParent", ValueFromPipeline=$true, Position=100)]
   [System.Windows.Automation.AutomationElement]$Parent = [UIAutomationHelper]::RootElement
,
   [Parameter(ParameterSetName="FromParent", Position="0")]
   [Alias("WindowName")]
   [String[]]$Name
,
   [Parameter(ParameterSetName="FromParent", Position="1")]
   [Alias("Type","Ct")]
   [System.Windows.Automation.ControlType]
   [StaticField(([System.Windows.Automation.ControlType]))]$ControlType
,
   [Parameter(ParameterSetName="FromParent")]
   [Alias("UId")]
   [String[]]$AutomationId
,
   ## Removed "Id" alias to allow get-process | Select-Window pipeline to find just MainWindowHandle
   [Parameter(ParameterSetName="FromParent", ValueFromPipelineByPropertyName=$true )]
   [Alias("Id")]
   [Int[]]$PID
,
   [Parameter(ParameterSetName="FromParent")]
   [Alias("Pn")]
   [String[]]$ProcessName
,
   [Parameter(ParameterSetName="FromParent")]
   [Alias("Cn")]
   [String[]]$ClassName
,
   [switch]$Recurse
,
   [switch]$Bare
)
process {

   Write-Debug "Parameters Found"
   Write-Debug ($PSBoundParameters | Format-Table | Out-String)

   $search = "Children"
   if($Recurse) { $search = "Descendants" }
   
   $condition = [System.Windows.Automation.Condition]::TrueCondition
   
   Write-Verbose $PSCmdlet.ParameterSetName
   switch -regex ($PSCmdlet.ParameterSetName) {
      "FromWindowHandle" {
         Write-Verbose "Finding from Window Handle $HWnd"
         $Element = $(
            foreach($hWnd in $WindowHandle) {
               [System.Windows.Automation.AutomationElement]::FromHandle( $hWnd )
            }
         )
         continue
      }
      "FromPoint" {
         Write-Verbose "Finding from Point $Point"
         $Element = $(
            foreach($pt in $Point) {
               [System.Windows.Automation.AutomationElement]::FromPoint( $pt )
            }
         )
         continue
      }
      "FromParent" {
         Write-Verbose "Finding from Parent!"
         ## [System.Windows.Automation.Condition[]]$conditions = [System.Windows.Automation.Condition]::TrueCondition
         [ScriptBlock[]]$filters = @()
         if($AutomationId) {
            [System.Windows.Automation.Condition[]]$current = $(
               foreach($aid in $AutomationId) {
                  new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::AutomationIdProperty), $aid
               }
            )
            if($current.Length -gt 1) {
               [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
            } elseif($current.Length -eq 1) {
               [System.Windows.Automation.Condition[]]$conditions += $current[0]
            }  
         }
         if($PID) {
            [System.Windows.Automation.Condition[]]$current = $(
               foreach($p in $PID) {
                  new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ProcessIdProperty), $p
               }
            )
            if($current.Length -gt 1) {
               [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
            } elseif($current.Length -eq 1) {
               [System.Windows.Automation.Condition[]]$conditions += $current[0]
            }         
         }
         if($ProcessName) {
            if($ProcessName -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($p in $ProcessName){ (Get-Process -id $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ProcessIdProperty)).ProcessName -like $p }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($p in Get-Process -Name $ProcessName) {
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ProcessIdProperty), $p.id
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }               
            }
         }
         if($Name) {
            Write-Verbose "Name: $Name"
            if($Name -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($n in $Name){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty) -like $n }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($n in $Name){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::NameProperty), $n, "IgnoreCase"
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }   
            }
         }
         if($ClassName) {
            if($ClassName -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($c in $ClassName){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ClassNameProperty) -like $c }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($c in $ClassName){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ClassNameProperty), $c, "IgnoreCase"
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }                  
            }
         }
         if($ControlType) {
            if($ControlType -match "\?|\*|\[") {
               [ScriptBlock[]]$filters += { $(foreach($c in $ControlType){ $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ControlTypeProperty) -like $c }) -contains $true } 
            } else {
               [System.Windows.Automation.Condition[]]$current = $(
                  foreach($c in $ControlType){
                     new-object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::ControlTypeProperty), $c
                  }
               )
               if($current.Length -gt 1) {
                  [System.Windows.Automation.Condition[]]$conditions += New-Object System.Windows.Automation.OrCondition $current
               } elseif($current.Length -eq 1) {
                  [System.Windows.Automation.Condition[]]$conditions += $current[0]
               }                  
            }
         }
         
         if($conditions.Length -gt 1) {
            [System.Windows.Automation.Condition]$condition = New-Object System.Windows.Automation.AndCondition $conditions
         } elseif($conditions) {
            [System.Windows.Automation.Condition]$condition = $conditions[0]
         } else {
            [System.Windows.Automation.Condition]$condition = [System.Windows.Automation.Condition]::TrueCondition
         }
         
         If($VerbosePreference -gt "SilentlyContinue") {
         
            function Write-Condition {
               param([Parameter(ValueFromPipeline=$true)]$condition, $indent = 0)
               process {
                  Write-Debug ($Condition | fl *  | Out-String)               
                  if($condition -is [System.Windows.Automation.AndCondition] -or $condition -is [System.Windows.Automation.OrCondition]) {
                     Write-Verbose ((" "*$indent) + $Condition.GetType().Name )
                     $condition.GetConditions().GetEnumerator() | Write-Condition -Indent ($Indent+4)
                  } elseif($condition -is [System.Windows.Automation.PropertyCondition]) {
                     Write-Verbose ((" "*$indent) + $Condition.Property.ProgrammaticName + " = '" + $Condition.Value + "' (" + $Condition.Flags + ")")
                  } else {
                     Write-Verbose ((" "*$indent) + $Condition.GetType().Name + " where '" + $Condition.Value + "' (" + $Condition.Flags + ")")
                  }
               }
            }
         
            Write-Verbose "CONDITIONS ============="
            $global:LastCondition = $condition
            foreach($c in $condition) {            
               Write-Condition $c
            }
            Write-Verbose "============= CONDITIONS"
         }
         
         if($filters.Count -gt 0) {
            $Element = $Parent.FindAll( $search, $condition ) | Where-Object { $item = $_;  foreach($f in $filters) { $item = $item | Where $f }; $item }
         } else {
            $Element = $Parent.FindAll( $search, $condition )
         }
      }  
   }
   
   Write-Verbose "Element Count: $(@($Element).Count)"
   if($Element) {
      foreach($el in $Element) {
         if($Bare) {
            Write-Output $el
         } else {
            $e = New-Object PSObject $el
            foreach($prop in $e.GetSupportedProperties() | Sort ProgrammaticName)
            {
               ## TODO: make sure all these show up: [System.Windows.Automation.AutomationElement] | gm -sta -type Property
               $propName = [System.Windows.Automation.Automation]::PropertyName($prop)
               Add-Member -InputObject $e -Type ScriptProperty -Name $propName -Value ([ScriptBlock]::Create( "`$this.GetCurrentPropertyValue( [System.Windows.Automation.AutomationProperty]::LookupById( $($prop.Id) ))" )) -EA 0
            }
            foreach($patt in $e.GetSupportedPatterns()| Sort ProgrammaticName)
            {
               Add-Member -InputObject $e -Type ScriptProperty -Name ($patt.ProgrammaticName.Replace("PatternIdentifiers.Pattern","") + "Pattern") -Value ([ScriptBlock]::Create( "`$this.GetCurrentPattern( [System.Windows.Automation.AutomationPattern]::LookupById( '$($patt.Id)' ) )" )) -EA 0
            }
            Write-Output $e
         }
      }
   }
}

}



#   [Cmdlet(VerbsCommon.Add, "UIAHandler")]
#   public class AddUIAHandlerCommand : PSCmdlet
#   {
#      private AutomationElement _parent = AutomationElement.RootElement;
#      private AutomationEvent _event = WindowPattern.WindowOpenedEvent;
#      private TreeScope _scope = TreeScope.Children;
#
#      [Parameter(ValueFromPipeline = true)]
#      [Alias("Parent", "Element", "Root")]
#      public AutomationElement InputObject { set { _parent = value; } get { return _parent; } }
#
#      [Parameter()]
#      public AutomationEvent Event { set { _event = value; } get { return _event; } }
#
#      [Parameter()]
#      public AutomationEventHandler ScriptBlock { set; get; }
#
#      [Parameter()]
#      public SwitchParameter Passthru { set; get; }
#
#      [Parameter()]
#      public TreeScope Scope { set { _scope = value; } get { return _scope; } }
#
#      protected override void ProcessRecord()
#      {
#         Automation.AddAutomationEventHandler(Event, InputObject, Scope, ScriptBlock);
#
#         if (Passthru.ToBool())
#         {
#            WriteObject(InputObject);
#         }
#
#         base.ProcessRecord();
#      }
#   }

Export-ModuleMember -cmdlet * -Function * -Alias *
# SIG # Begin signature block
# MIIfIAYJKoZIhvcNAQcCoIIfETCCHw0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtL6Jm12dWBELoaH5g6kpaTxj
# toagghpSMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggRPMIIDuKADAgECAgQHJ1g9MA0GCSqGSIb3DQEBBQUAMHUxCzAJ
# BgNVBAYTAlVTMRgwFgYDVQQKEw9HVEUgQ29ycG9yYXRpb24xJzAlBgNVBAsTHkdU
# RSBDeWJlclRydXN0IFNvbHV0aW9ucywgSW5jLjEjMCEGA1UEAxMaR1RFIEN5YmVy
# VHJ1c3QgR2xvYmFsIFJvb3QwHhcNMTAwMTEzMTkyMDMyWhcNMTUwOTMwMTgxOTQ3
# WjBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3Vy
# YW5jZSBFViBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# xszlc+b71LvlLS0ypt/lgT/JzSVJtnEqw9WUNGeiChywX2mmQLHEt7KP0JikqUFZ
# OtPclNY823Q4pErMTSWC90qlUxI47vNJbXGRfmO2q6Zfw6SE+E9iUb74xezbOJLj
# BuUIkQzEKEFV+8taiRV+ceg1v01yCT2+OjhQW3cxG42zxyRFmqesbQAUWgS3uhPr
# UQqYQUEiTmVhh4FBUKZ5XIneGUpX1S7mXRxTLH6YzRoGFqRoc9A0BBNcoXHTWnxV
# 215k4TeHMFYE5RG0KYAS8Xk5iKICEXwnZreIt3jyygqoOKsKZMK/Zl2VhMGhJR6H
# XRpQCyASzEG7bgtROLhLywIDAQABo4IBbzCCAWswEgYDVR0TAQH/BAgwBgEB/wIB
# ATBTBgNVHSAETDBKMEgGCSsGAQQBsT4BADA7MDkGCCsGAQUFBwIBFi1odHRwOi8v
# Y3liZXJ0cnVzdC5vbW5pcm9vdC5jb20vcmVwb3NpdG9yeS5jZm0wDgYDVR0PAQH/
# BAQDAgEGMIGJBgNVHSMEgYEwf6F5pHcwdTELMAkGA1UEBhMCVVMxGDAWBgNVBAoT
# D0dURSBDb3Jwb3JhdGlvbjEnMCUGA1UECxMeR1RFIEN5YmVyVHJ1c3QgU29sdXRp
# b25zLCBJbmMuMSMwIQYDVQQDExpHVEUgQ3liZXJUcnVzdCBHbG9iYWwgUm9vdIIC
# AaUwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL3d3dy5wdWJsaWMtdHJ1c3QuY29t
# L2NnaS1iaW4vQ1JMLzIwMTgvY2RwLmNybDAdBgNVHQ4EFgQUsT7DaQP4v0cB1Jgm
# GggC72NkK8MwDQYJKoZIhvcNAQEFBQADgYEALnaF2TeWba+J8wZ4gjHERgcfZcmO
# s8lUeObRQt91Lh5V6vf6mwTAdXvReTwF7HnEUt2mA9enUJk/BVnaxlX0hpwNZ6NJ
# BJUyHceH7IWvZG7VxV8Jp0B9FrpJDaL99t9VMGzXeMa5z1gpZBZMoyCBR7FEkoQW
# G29KvCHGCj3tM8owggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqG
# SIb3DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jw
# b3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNl
# cyBDQSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkG
# A1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQD
# EytTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEK
# U5OwmNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf
# 2Gi0jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQ
# DhfultthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6
# Anqhd5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrF
# xeozC9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQID
# AQABo4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5o
# dHRwOi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6
# Ly90cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUw
# MzAxoC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcy
# LmNybDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAd
# BgNVHQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzM
# zHSa1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ij
# hCcHbxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebD
# Zw73BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmR
# DoDREfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2b
# W+IWyhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5
# Mysue7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzY
# BHUwggafMIIFh6ADAgECAhAOaQaYwhTIerW2BLkWPNGQMA0GCSqGSIb3DQEBBQUA
# MHMxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xMjAwBgNVBAMTKURpZ2lDZXJ0IEhpZ2ggQXNzdXJh
# bmNlIENvZGUgU2lnbmluZyBDQS0xMB4XDTEyMDMyMDAwMDAwMFoXDTEzMDMyMjEy
# MDAwMFowbTELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5ldyBZb3JrMRcwFQYDVQQH
# Ew5XZXN0IEhlbnJpZXR0YTEYMBYGA1UEChMPSm9lbCBILiBCZW5uZXR0MRgwFgYD
# VQQDEw9Kb2VsIEguIEJlbm5ldHQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDaiAYAbz13WMx9Em/Z3dTWUKxbyiTsaSOctgOfTMLUAurXWtY3k1XBVufX
# feL4pXQ7yQzm93YzvETwKdUCDJuOSu9EPYioy2nhKvBC6IaJUaw1VY7e9IsdxaxL
# 8js3RQilLk+FO4UHg9w7L8wdHgXaDoksysC2SlhbFq4AVl8XC4R+bq+pahsdMO3n
# Ab7Oo5PExKLVS8vl8QwOh6MaqquIjHmYoPOu9Rv8As0pnWsY9aVPs7T9QetXlW45
# +CKPhdUoEB1yD0kvGTIAQgn5W9VDYmfeVU40IIdt+7khWF10yu7zVT+/lauPzRmv
# CHZMfbmqVyVQqvp5dEu0/7EWbbcLAgMBAAGjggMzMIIDLzAfBgNVHSMEGDAWgBSX
# SAPrFQhrubJYI8yULvHGZdJkjjAdBgNVHQ4EFgQUmJxEqr9ewFZG4rNTp5NQIEIJ
# TrkwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMGkGA1UdHwRi
# MGAwLqAsoCqGKGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9oYS1jcy0yMDExYS5j
# cmwwLqAsoCqGKGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9oYS1jcy0yMDExYS5j
# cmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDATCCAaQwOgYIKwYBBQUH
# AgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5o
# dG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0
# AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1
# AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABp
# AGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBl
# AGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBo
# AGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAg
# AGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAg
# AGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYYGCCsGAQUFBwEBBHoweDAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFAGCCsGAQUFBzAChkRo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNl
# Q29kZVNpZ25pbmdDQS0xLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBBQUA
# A4IBAQAch95ik7Qm12L9Olwjp5ZAhhTYAs7zjtD3WMsTpaJTq7zA3q2QeqB46WzT
# vRINQr4LWtWhcopnQl5zaTV1i6Qo+TJ/epRE/KH9oLeEnRbBuN7t8rv0u31kfAk5
# Gl6wmvBrxPreXeossuU9ohij9uqIyk1lF85yW6QqDaE7rvIxpCXwMQv8PlQ/VdlK
# EXbNtq4frbvMQLkpcZljbJRuZYbY3SgfGv6rgbJ93Qw+1Tlq9Y4gsHRmw35uv5IJ
# VUrqcrNq5cyTgdeYodpftzKyqmZCIVvv8nu09DTfspAocJj9n5+XRqtEKIeKH9D/
# mjC/nVZIo+JpSuQG90nSYpUr4xwfMIIGvzCCBaegAwIBAgIQCBxX7l1w65ugsVIM
# cpwbCTANBgkqhkiG9w0BAQUFADBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJE
# aWdpQ2VydCBIaWdoIEFzc3VyYW5jZSBFViBSb290IENBMB4XDTExMDIxMDEyMDAw
# MFoXDTI2MDIxMDEyMDAwMFowczELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEyMDAGA1UEAxMpRGln
# aUNlcnQgSGlnaCBBc3N1cmFuY2UgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDF+SPmlCfEgBSkgDJfQKONb3DA5TZxcTp1
# pKoakpSJXqwjcctOZ31BP6rjS7d7vp3BqDiPaS86JOl3WRLHZgRDwg0mgolAGfIs
# 6udM53wFGrj/iAlPJjfvOqT6ImyIyUobYfKuEF5vvNF5m1kYYOXuKbUDKqTO8YMZ
# T2kFcygJ+yIQkyKgkBkaTDHy0yvYhEOvPGP/mNsg0gkrVMHq/WqD5xCjEnH11tfh
# EnrV4FZazuoBW2hlW8E/WFIzqTVhTiLLgco2oxLLBtbPG00YfrmSuRLPQCbYmjaF
# sxWqR5OEawe7vNWz3iUAEYkAaMEpPOo+Le5Qq9ccMAZ4PKUQI2eRAgMBAAGjggNU
# MIIDUDAOBgNVHQ8BAf8EBAMCAQYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNV
# HSAEggG6MIIBtjCCAbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsG
# AQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABD
# AGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABh
# AGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQBy
# AHQAIABFAFYAIABDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBn
# ACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABs
# AGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABp
# AG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBl
# AGYAZQByAGUAbgBjAGUALjAPBgNVHRMBAf8EBTADAQH/MH8GCCsGAQUFBwEBBHMw
# cTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEkGCCsGAQUF
# BzAChj1odHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNz
# dXJhbmNlRVZSb290Q0EuY3J0MIGPBgNVHR8EgYcwgYQwQKA+oDyGOmh0dHA6Ly9j
# cmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEhpZ2hBc3N1cmFuY2VFVlJvb3RDQS5j
# cmwwQKA+oDyGOmh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEhpZ2hB
# c3N1cmFuY2VFVlJvb3RDQS5jcmwwHQYDVR0OBBYEFJdIA+sVCGu5slgjzJQu8cZl
# 0mSOMB8GA1UdIwQYMBaAFLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEB
# BQUAA4IBAQCCBemFr6dMv6/OPbLqYLFo3mfC0ssm4MMvm7VrDlOQhfab4DUC//pp
# g6q0dDIUPC4QTCibCq0ICfnzhBGTj8tgQFbpdy9psoOZVatHJJbLf0uwELSXv8Sl
# mQb+juwUUB5eV5fLR7k02fw6ov9QKcIKYgTu3pY6b6DChQ9v/AjkMnvThK5pYAlG
# Jpzo8P//htnICTpmw6c2jxhP6LGWki5OvgunM5CuvG5P8X6NtEYOZPlZBiIhZABL
# 4noIA+e8iZCeQk8BwLYWf3XqRrKlVC+Mk80RNjRqKFfMlD/pfMgYAwMEfkPa+Zeh
# WUfaEqrgbTgAXTUrxSKGywbKvHpNPSZGMYIEODCCBDQCAQEwgYcwczELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEyMDAGA1UEAxMpRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2UgQ29kZSBT
# aWduaW5nIENBLTECEA5pBpjCFMh6tbYEuRY80ZAwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEpc
# xm/enjt6WdToIKI5Zj4ZtUh/MA0GCSqGSIb3DQEBAQUABIIBADj8ZsvgtZablGVx
# A6GfN3o9URqkugHDJToWZti2kX8cmCt9T+bghtkSKYwR0nDIc7L2uL5HovWaBscv
# /L9QPy6PlHiD53RrTT9QXYQ43tjnyR6Jd9Q4r/9I83TPtPZvjChsVEq/V3HTCuRZ
# V2iXB0OyWSH1EiiczqsjNOgM6fH1lpUibucuQYC6twkonqm1RL9vckkiClww7kSe
# rchTHIXgJrEX79e2/20EEu1zCvDNkw9TB5Db55yV4xDodAeekF4UKUSpMqvYLhz5
# HHUs9PxUErKFLCSMaIai0at8iAr+6cND8STbApYRXBDNawm1PEKLBXXaXK4c/4xg
# O76cT2OhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTMwMjAyMjAwMDEzWjAjBgkqhkiG9w0BCQQxFgQUL30U
# fC9V3lvWclZ+XK2MyEMQlZAwDQYJKoZIhvcNAQEBBQAEggEATKl0ITIxM+4GmUKR
# Wt02io+YEWMNSGTyikiLhkHIfcLot+oiVhOH0pkkFGXrDtrJo1OdHkDTEM7w7TRN
# We4mS4ApP8pbfi4t3kErrrJICwJ2P+VFm0OvDdVq2EdX2u2izNRs2wWufXmv9orf
# lxzZQWQ5OHPWuga18zP4/kaBVbYfS2Mkc47MsPM37GmlbAGqFS4A25AP8JUPrk3L
# bT9eqT72GVkmVY2W/MHl4TOcZZEdxPDaQzICNAlRhZVt06guqMlGi3n+62dmsS5E
# yNw4MnWDSwM4L+jlI709bmiIHqtWa4rJvghV6SvuD6UvkgF6LeaX/J2fc1geQQz9
# 0YWbhw==
# SIG # End signature block