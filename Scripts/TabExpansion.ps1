## Tab-Completion
#################
## For V2CTP3.
## This won't work on V1 and V2CTP and V2CTP2.
## Please dot souce this script file.
## In first loading, it may take a several minutes, in order to generate ProgIDs and TypeNames list.
## 
## What this can do is:
##
## [datetime]::n<tab>
## [datetime]::now.d<tab>
## $a = New-Object "Int32[,]" 2,3; $b = "PowerShell","PowerShell"
## $c = [ref]$a; $d = [ref]$b,$c
## $d[0].V<tab>[0][0].Get<tab>
## $d[1].V<tab>[0,0].tos<tab>
## $function:a<tab>
## $env:a<tab>
## [System.Type].a<tab>
## [datetime].Assembly.a<tab>
## ).a<tab> # shows System.Type properties and methods...

## #native command name expansion
## fsu<tab>

## #command option name expansion (for fsutil ipconfig net powershell only)
## fsutil <tab>
## ipconfig <tab>
## net <tab>
## powershell <tab>

## #TypeNames and Type accelerators expansion
## [Dec<tab>
## [system.Man<tab>.auto<tab>.p<tab>
## New-Object -TypeName IO.Dir<tab>
## New-Object System.win<tab>.for<tab>.bu<tab>

## #ProgIDs expansion
## New-Object -Com shel<tab>

## #Enum option expansion
## Set-ExecutionPolicy <tab>
## Set-ExecutionPolicy All<tab>
## Set-ExcusionPolisy -ex <tab>
## Get-TraceSource Inte<tab>
## iex -Errora <tab> -wa Sil<tab>

## #WmiClasses expansion
## Get-WmiObject -class Win32_<tab>
## gwmi __Instance<tab>

## #Encoding expansion
## [Out-File | Export-CSV | Select-String | Export-Clixml] -enc <tab>
## [Add-Content | Get-Content | Set-Content} -Encoding Big<tab>

## #PSProvider name expansion
## [Get-Location | Get-PSDrive | Get-PSProvider | New-PSDrive | Remove-PSDrive] -PSProvider <tab>
## Get-PSProvider <tab>
## pwd -psp al<tab>

## #PSDrive name expansion
## [Get-PSDrive | New-PSDrive | Remove-PSDrive] [-Name] <tab>
## Get-PSDrive <tab>
## pwd -psd <tab>

## #PSSnapin name expansion
## [Add-PSSnapin | Get-PSSnapin | Remove-PSSnapin ] [-Name] <tab>
## Get-Command -PSSnapin <tab>
## Remove-PSSnapin <tab>
## Get-PSSnapin M<tab>

## #Eventlog name and expansion
## Get-Eventlog -Log <tab>
## Get-Eventlog w<tab>

## #Eventlog's entrytype expansion
## Get-EventLog -EntryType <tab>
## Get-EventLog -EntryType Er<tab>
## Get-EventLog -Ent <tab>

## #Service name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-Name] <tab>
## New-Service -DependsOn <tab>
## New-Service -Dep e<tab>
## Get-Service -n <tab>
## Get-Service <tab>,a<tab>,p<tab>
## gsv <tab>

## #Service display name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-DisplayName] <tab>
## Get-Service -Dis <tab>
## gsv -Dis <tab>,w<tab>,b<tab>

## #Cmdlet and Topic name expansion (this also support default help function and man alias)
## Get-Help [-Name] about_<tab>
## Get-Help <tab>

## #Category name expansion (this also support default help function and man alias)
## Get-Help -Category c<tab>,<tab>

## #Command name expansion
## Get-Command [-Name] <tab>
## Get-Command -Name <tab>
## gcm a<tab>,<tab>

## #Scope expansion
## [Clear-Variable | Export-Alias | Get-Alias | Get-PSDrive | Get-Variable | Import-Alias
## New-Alias | New-PSDrive | New-Variable | Remove-Variable | Set-Alias | Set-Variable] -Scope <tab>
## Clear-Variable -Scope G<tab>
## Set-Alias  -s <tab>

## #Process name expansion
## [Get-Process | Stop-Process] [-Name] <tab>
## Stop-Process -Name <tab>
## Stop-Process -N pow<tab>
## Get-Process <tab>
## ps power<tab>

## #Trace sources expansion
## [Trace-Command | Get-TraceSource | Set-TraceSource] [-Name] <tab>,a<tab>,p<tab>

## #Trace -ListenerOption expansion
## [Set-TraceSource | Trace-Command] -ListenerOption <tab>
## Set-TraceSource -Lis <tab>,n<tab>

## #Trace -Option expansion
## [Set-TraceSource | Trace-Command] -Option <tab>
## Set-TraceSource -op <tab>,con<tab>

## #ItemType expansion
## New-Item -Item <tab>
## ni -ItemType d<tab>

## #ErrorAction and WarningAction option expansion
## CMDLET [-ErrorAction | -WarningAction] <tab>
## CMDLET -Errora s<tab>
## CMDLET -ea con<tab>
## CMDLET -wa <tab>

## #Continuous expansion with comma when parameter can treat multiple option
## # if there are spaces, occur display bug in the line
## # if strings contains '$' or '-', not work
## Get-Command -CommandType <tab>,<tab><tab>,cm<tab>
## pwd -psp <tab>,f<tab>,va<tab>
## Get-EventLog -EntryType <tab>,i<tab>,s<tab>

## #Enum expansion in method call expression
## # this needs one or more spaces after left parenthesis or comma
## $str = "day   night"
## $str.Split( " ",<space>rem<tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" ) <Enter> ERROR
## $str.Split( " ", "RemoveEmptyEntries" -as<space><tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" -as [System.StringSplitOptions] ) <Enter> Success
## $type = [System.Type]
## $type.GetMembers(<space>Def<tab>
## [IO.Directory]::GetFiles( "C:\", "*",<space>All<tab>
## # this can do continuous enum expansion with comma and no spaces
## $type.GetMembers( "IgnoreCase<comma>Dec<tab><comma>In<tab>"
## [IO.Directory]::GetAccessControl( "C:\",<space>au<tab><comma>ac<tab><comma>G<tab>

## #Better '$_.' expansion when cmdlet output objects or method return objects
## ls |group { $_.Cr<tab>.Tost<tab>"y")} | tee -var foo| ? { $_.G<tab>.c<tab> -gt 5 } | % { md $_.N<tab> ; copy $_.G<tab> $_.N<tab>  }
## [IO.DriveInfo]::GetDrives() | ? { $_.A<tab> -gt 1GB }
## $Host.UI.RawUI.GetBufferContents($rect) | % { $str += $_.c<tab> }
## gcm Add-Content |select -exp Par<tab>| select -ExpandProperty Par<tab> | ? { $_.Par<tab>.N<tab> -eq "string" }
## $data = Get-Process
## $data[2,4,5]  | % { $_.<tab>
## #when Get-PipeLineObject failed, '$_.' shows methods and properties name of FileInfo and String and Type

## #Property name expansion by -Property parameter
## [ Format-List | Format-Custom | Format-Table | Format-Wide | Compare-Object |
##  ConvertTo-Html | Measure-Object | Select-Object | Group-Object | Sort-Object ] [-Property] <tab>
## Select-Object -ExcludeProperty <tab>
## Select-Object -ExpandProperty <tab>
## gcm Get-Acl|select -exp Par<tab>
## ps |group na<tab>
## ls | ft A<tab>,M<tab>,L<tab>

## #Hashtable key expansion in the variable name and '.<tab>'
## Get-Process | Get-Unique | % { $hash += @{$_.ProcessName=$_} }
## $hash.pow<tab>.pro<tab>

## #Parameter expansion for function, filter and script
## man -f<tab>
## 'param([System.StringSplitOptions]$foo,[System.Management.Automation.ActionPreference]$bar,[System.Management.Automation.CommandTypes]$baz) {}' > foobar.ps1
## .\foobar.ps1 -<tab> -b<tab>

## #Enum expansion for function, filter and scripts
## # this can do continuous enum expansion with comma and no spaces
## .\foobar.ps1 -foo rem<tab> -bar <tab><comma>c<tab><comma>sc<tab> -ea silent<tab> -wa con<tab>

## #Enum expansion for assignment expression
## #needs space(s) after '=' and comma
## #strongly-typed with -as operator and space(s)
## $ErrorActionPreference =<space><tab>
## $cmdtypes = New-Object System.Management.Automation.CommandTypes[] 3
## $cmdtypes =<space><tab><comma><space>func<tab><comma><space>cmd<tab> -as<space><tab>

## #Path expansion with variable and '\' or '/'
## $PWD\../../<tab>\<tab>
## "$env:SystemDrive/pro<tab>/<tab>

## #Operator expansion which starts with '-'
## "Power","Shell" -m<tab> "Power" -r<tab> '(Pow)(er)','$1d$2'
## 1..9 -co<tab> 5

## #Keyword expansion
## fu<tab> test { p<tab> $foo, $bar ) b<tab> "foo" } pr<tab> $_ } en<tab> "$bar" } }

## #Variable name expansion (only global scope)
## [Clear-Variable | Get-Variable | New-Variable | Remove-Variable | Set-Variable] [-Name] <tab>
## [Cmdlet | Function | Filter | ExternalScript] -ErrorVariable <tab>
## [Cmdlet | Function | Filter | ExternalScript] -OutVariable <tab>
## Tee-Object -Variable <tab>
##  gv pro<tab>,<tab>
##  Remove-Variable -Name out<tab>,<tab>,ps<tab>
##  ... | ... | tee -v <tab>

## #Alias name expansion
## [Get-Alias | New-Alias | Set-Alias] [-Name] <tab>
## Export-Alias -Name <tab>
##  Get-Alias i<tab>,e<tab>,a<tab>
##  epal -n for<tab>

## #Property name expansion with -groupBy parameter
## [Format-List | Format-Custom | Format-Table | Format-Wide] -groupBy <tab>
##  ps | ft -g <tab>
##  gcm | Format-Wide -GroupBy Par<tab>

## #Type accelerators expansion with no charactors
##  [<tab>
##  New-Object -typename <tab>
##  New-Object <tab>

## # File glob expansion with '@'
##  ls *.txt@<tab>
##  ls file.txt, foo1.txt, 'bar``[1``].txt', 'foo bar .txt'	# 1 <tab> expanding with comma
##  ls * -Filter *.txt						# 2 <tab> refactoring 
##  ls *.txt							# 3 <tab> (or 1 <tab> & 1 <shift>+<tab>) return original glob pattern

## This can also use '^'(hat) or '~'(tilde) for Excluding
##  ls <hat>*.txt@<tab>
##  ls foo.ps1, 'bar``[1``].xml'		# 1 <tab> expanding with comma
##  ls * -Filter * -Excluding *.txt		# 2 <tab> refactoring 
##  *.txt<tilde>foo*<tilde>bar*@<tab>
##  ls file.txt					# 1 <tab> expanding with comma
##  ls * -Filter *.txt -Excluding foo*, bar*	# 2 <tab> refactoring 

## # Ported history expansion from V2CTP3 TabExpansion with '#' ( #<pattern> or #<id> )
##  ls * -Filter * -Excluding foo*, bar*<Enter>
##  #ls<tab>
##  #1<tab>

## # Command buffer stack with ';'(semicolon)
##  ls * -Filter * -Excluding foo*, bar*<semicolon><tab> # push command1
##  echo "PowerShell"<semicolon><tab> # push command2
##  get-process<semicolon><tab> # push command3
##  {COMMAND}<Enter> # execute another command 
##  get-process # Auto pop command3 from stack by LIFO
## This can also hand-operated pop with ';,'(semicolon&comma) or ';:'(semicolon&colon)
##  get-process; <semicolon><comma><tab>
##  get-process; echo "PowerShell" # pop command2 from stack by LIFO

## # Function name expansion after 'function' or 'filter' keywords
## function cl<tab>

## #Switch syntax option expansion
##  switch -w<tab> -f<tab>

## #Better powershell.exe option expansion with '-'
##  powershell -no<tab> -<tab> -en<tab>

## #A part of PowerShell attributes expansion ( CmdletBinding, Parameter, Alias, Validate*, Allow* )
##  [par<tab>
##  [cmd<tab>

## #Member expansion for CmdletBinding and Parameter attributes
##  [Parameter(man<tab>,<tab>1,val<tab>$true)]
##  [CmdletBinding( <tab>"foo", su<tab>$true)]

## #Several current date/time formats with Ctrl+D
##  <Ctrl+D><tab><tab><tab><tab><tab>...

## #Hand-operated pop from command buffer with Ctrl+P (this is also available with ';:' or ';,')
##  <command>;<tab> # push command
##  <Ctrl+D><tab> # pop

## #Paste clipboard with Ctrl+V
##  <Ctrl+V><tab>

### Generate ProgIDs list...
if ( Test-Path $PSHOME\ProgIDs.txt )
{
	$_ProgID = type $PSHOME\ProgIDs.txt -ReadCount 0
}
else
{
	$_HKCR = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\")
	$_ProgID = New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) )
	foreach ( $_subkey in $_HKCR.GetSubKeyNames() )
	{
		foreach ( $_i in [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\$_subkey\ProgID") )
		{
			if ($_i -ne $null)
			{
				$_ProgID.Add($_i.GetValue(""))
			}
		}
	}
	'$_ProgID was updated...' | Out-Host
	$_ProgID = $_ProgID|sort -Unique

	Set-Content -Value $_ProgID -Path $PSHOME\ProgIDs.txt -Verbose
}

### Generate TypeNames list...

if ( Test-Path $PSHOME\TypeNames.txt )
{
	$_TypeNames = type $PSHOME\TypeNames.txt -ReadCount 0
}
else
{
	$_TypeNames = New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) )
	foreach ( $_asm in [AppDomain]::CurrentDomain.GetAssemblies() )
	{
		foreach ( $_type in $_asm.GetTypes() )
		{
			$_TypeNames.Add($_type.FullName)
		}
	}
	'$_TypeNames was updated...' | Out-Host
	$_TypeNames = $_TypeNames | sort -Unique

	Set-Content -Value $_TypeNames -Path $PSHOME\TypeNames.txt -Verbose
}

if ( Test-Path $PSHOME\TypeNames_System.txt )
{
	$_TypeNames_System = type $PSHOME\TypeNames_System.txt -ReadCount 0
}
else
{
	$_TypeNames_System = $_TypeNames -like "System.*" -replace '^System\.'
	'$_TypeNames_System was updated...' | Out-Host
	Set-Content -Value $_TypeNames_System -Path $PSHOME\TypeNames_System.txt -Verbose
}

### Generate WMIClasses list...
if ( Test-Path $PSHOME\WMIClasses.txt )
{
	$_WMIClasses = type $PSHOME\WMIClasses.txt -ReadCount 0
}
else
{
	$_WMIClasses = New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) )
	foreach ( $_class in gwmi -List )
	{
		$_WMIClasses.Add($_class.Name)
	}
	$_WMIClasses = $_WMIClasses | sort -Unique
	'$_WMIClasses was updated...' | Out-Host
	Set-Content -Value $_WMIClasses -Path $PSHOME\WMIClasses.txt -Verbose
}

[Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" ) | Out-Null
$global:_cmdstack = New-Object Collections.Stack
$global:_snapin = $null
$global:_TypeAccelerators = "ADSI", "Array", "Bool", "Byte", "Char", "Decimal", "Double", "float", "hashtable", "int", "Long", "PSObject", "ref",
"Regex", "ScriptBlock", "Single", "String", "switch", "Type", "WMI", "WMIClass", "WMISearcher", "xml"

iex (@'
function prompt {
if ($_cmdstack.Count -gt 0) {
$line = $global:_cmdstack.Pop() -replace '([[\]\(\)+{}?~%])','{$1}'
[System.Windows.Forms.SendKeys]::SendWait($line)
}
'@ + @"
${function:prompt}
}
"@)

function Write-ClassNames ( $data, $i, $prefix = '', $sep = '.' )
{
	$preItem = ""
	foreach ( $class in $data -like $_opt )
	{
		$Item = $class.Split($sep)
		if ( $preItem -ne $Item[$i] )
		{
			if ( $i + 1 -eq $Item.Count )
			{
				if ( $prefix -eq "[" )
				{
					$suffix = "]"
				}
				elseif ( $sep -eq "_" )
				{
					$suffix = ""
				}
				else
				{
					$suffix = " "
				}
			}
			else
			{
				$suffix = ""
			}
			$prefix + $_opt.Substring(0, $_opt.LastIndexOf($sep)+1) + $Item[$i] + $suffix

			$preItem = $Item[$i]
		}
	}
}

function Get-PipeLineObject {

	$i = -2
	$property = $null
	do {
		$str = $line.Split("|")
		# extract the command name from the string
		# first split the string into statements and pipeline elements
		# This doesn't handle strings however.
		$_cmdlet = [regex]::Split($str[$i], '[|;=]')[-1]

		# take the first space separated token of the remaining string
		# as the command to look up. Trim any leading or trailing spaces
		# so you don't get leading empty elements.
		$_cmdlet = $_cmdlet.Trim().Split()[0]

		if ( $_cmdlet -eq "?" )
		{
			$_cmdlet = "Where-Object"
		}

		$global:_exp = $_cmdlet

		# now get the info object for it...
		$_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet)[0]

		# loop resolving aliases...
		while ($_cmdlet.CommandType -eq 'alias')
		{
			$_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet.Definition)[0]
		}

		if ( "Select-Object" -eq $_cmdlet )
		{
			if ( $str[$i] -match '\s+-Exp\w*[\s:]+(\w+)' )
			{
				$property = $Matches[1] + ";" + $property
			}
		}

		$i--
	} while ( "Get-Unique", "Select-Object", "Sort-Object", "Tee-Object", "Where-Object" -contains $_cmdlet )

	if ( $global:_forgci -eq $null )
	{
		$a = @(ls "Alias:\")[0]
		$e = @(ls "Env:\")[0]
		$f = @(ls "Function:\")[0]
		$h = @(ls "HKCU:\")[0]
		$v = @(ls "Variable:\")[0]
		$c = @(ls "cert:\")[0]
		$global:_forgci = gi $PSHOME\powershell.exe |
		Add-Member 'NoteProperty' CommandType $f.CommandType -P |
		Add-Member 'NoteProperty' Definition $a.Definition -P |
		Add-Member 'NoteProperty' Description $a.Description -P |
		Add-Member 'NoteProperty' Key $e.Key -P |
		Add-Member 'NoteProperty' Location $c.Location -P |
		Add-Member 'NoteProperty' LocationName $c.LocationName -P |
		Add-Member 'NoteProperty' Options $a.Options -P |
		Add-Member 'NoteProperty' ReferencedCommand $a.ReferencedCommand -P |
		Add-Member 'NoteProperty' ResolvedCommand $a.ResolvedCommand -P |
		Add-Member 'NoteProperty' ScriptBlock $f.ScriptBlock -P |
		Add-Member 'NoteProperty' StoreNames $c.StoreNames -P |
		Add-Member 'NoteProperty' SubKeyCount $h.SubKeyCount -P |
		Add-Member 'NoteProperty' Value $e.Value -P |
		Add-Member 'NoteProperty' ValueCount $h.ValueCount -P |
		Add-Member 'NoteProperty' Visibility $a.Visibility -P |
		Add-Member 'NoteProperty' Property $h.Property -P |
		Add-Member 'NoteProperty' ResolvedCommandName $a.ResolvedCommandName -P |
		Add-Member 'ScriptMethod' Close {} -P |
		Add-Member 'ScriptMethod' CreateSubKey {} -P |
		Add-Member 'ScriptMethod' DeleteSubKey {} -P |
		Add-Member 'ScriptMethod' DeleteSubKeyTree {} -P |
		Add-Member 'ScriptMethod' DeleteValue {} -P |
		Add-Member 'ScriptMethod' Flush {} -P |
		Add-Member 'ScriptMethod' GetSubKeyNames {} -P |
		Add-Member 'ScriptMethod' GetValue {} -P |
		Add-Member 'ScriptMethod' GetValueKind {} -P |
		Add-Member 'ScriptMethod' GetValueNames {} -P |
		Add-Member 'ScriptMethod' IsValidValue {} -P |
		Add-Member 'ScriptMethod' OpenSubKey {} -P |
		Add-Member 'ScriptMethod' SetValue {} -P
	}

	if ( $global:_mix -eq $null )
	{
		$f = gi $PSHOME\powershell.exe
		$t = [type]
		$s = ""
		$global:_mix = `
		Add-Member -InputObject (New-Object PSObject) 'NoteProperty' Mode $f.Mode -P |
		Add-Member 'NoteProperty' Assembly $t.Assembly -P |
		Add-Member 'NoteProperty' AssemblyQualifiedName $t.AssemblyQualifiedName -P |
		Add-Member 'NoteProperty' Attributes $f.Attributes -P |
		Add-Member 'NoteProperty' BaseType $t.BaseType -P |
		Add-Member 'NoteProperty' ContainsGenericParameters $t.ContainsGenericParameters -P |
		Add-Member 'NoteProperty' CreationTime $f.CreationTime -P |
		Add-Member 'NoteProperty' CreationTimeUtc $f.CreationTimeUtc -P |
		Add-Member 'NoteProperty' DeclaringMethod $t.DeclaringMethod -P |
		Add-Member 'NoteProperty' DeclaringType $t.DeclaringType -P |
		Add-Member 'NoteProperty' Exists $f.Exists -P |
		Add-Member 'NoteProperty' Extension $f.Extension -P |
		Add-Member 'NoteProperty' FullName $f.FullName -P |
		Add-Member 'NoteProperty' GenericParameterAttributes $t.GenericParameterAttributes -P |
		Add-Member 'NoteProperty' GenericParameterPosition $t.GenericParameterPosition -P |
		Add-Member 'NoteProperty' GUID $t.GUID -P |
		Add-Member 'NoteProperty' HasElementType $t.HasElementType -P |
		Add-Member 'NoteProperty' IsAbstract $t.IsAbstract -P |
		Add-Member 'NoteProperty' IsAnsiClass $t.IsAnsiClass -P |
		Add-Member 'NoteProperty' IsArray $t.IsArray -P |
		Add-Member 'NoteProperty' IsAutoClass $t.IsAutoClass -P |
		Add-Member 'NoteProperty' IsAutoLayout $t.IsAutoLayout -P |
		Add-Member 'NoteProperty' IsByRef $t.IsByRef -P |
		Add-Member 'NoteProperty' IsClass $t.IsClass -P |
		Add-Member 'NoteProperty' IsCOMObject $t.IsCOMObject -P |
		Add-Member 'NoteProperty' IsContextful $t.IsContextful -P |
		Add-Member 'NoteProperty' IsEnum $t.IsEnum -P |
		Add-Member 'NoteProperty' IsExplicitLayout $t.IsExplicitLayout -P |
		Add-Member 'NoteProperty' IsGenericParameter $t.IsGenericParameter -P |
		Add-Member 'NoteProperty' IsGenericType $t.IsGenericType -P |
		Add-Member 'NoteProperty' IsGenericTypeDefinition $t.IsGenericTypeDefinition -P |
		Add-Member 'NoteProperty' IsImport $t.IsImport -P |
		Add-Member 'NoteProperty' IsInterface $t.IsInterface -P |
		Add-Member 'NoteProperty' IsLayoutSequential $t.IsLayoutSequential -P |
		Add-Member 'NoteProperty' IsMarshalByRef $t.IsMarshalByRef -P |
		Add-Member 'NoteProperty' IsNested $t.IsNested -P |
		Add-Member 'NoteProperty' IsNestedAssembly $t.IsNestedAssembly -P |
		Add-Member 'NoteProperty' IsNestedFamANDAssem $t.IsNestedFamANDAssem -P |
		Add-Member 'NoteProperty' IsNestedFamily $t.IsNestedFamily -P |
		Add-Member 'NoteProperty' IsNestedFamORAssem $t.IsNestedFamORAssem -P |
		Add-Member 'NoteProperty' IsNestedPrivate $t.IsNestedPrivate -P |
		Add-Member 'NoteProperty' IsNestedPublic $t.IsNestedPublic -P |
		Add-Member 'NoteProperty' IsNotPublic $t.IsNotPublic -P |
		Add-Member 'NoteProperty' IsPointer $t.IsPointer -P |
		Add-Member 'NoteProperty' IsPrimitive $t.IsPrimitive -P |
		Add-Member 'NoteProperty' IsPublic $t.IsPublic -P |
		Add-Member 'NoteProperty' IsSealed $t.IsSealed -P |
		Add-Member 'NoteProperty' IsSerializable $t.IsSerializable -P |
		Add-Member 'NoteProperty' IsSpecialName $t.IsSpecialName -P |
		Add-Member 'NoteProperty' IsUnicodeClass $t.IsUnicodeClass -P |
		Add-Member 'NoteProperty' IsValueType $t.IsValueType -P |
		Add-Member 'NoteProperty' IsVisible $t.IsVisible -P |
		Add-Member 'NoteProperty' LastAccessTime $f.LastAccessTime -P |
		Add-Member 'NoteProperty' LastAccessTimeUtc $f.LastAccessTimeUtc -P |
		Add-Member 'NoteProperty' LastWriteTime $f.LastWriteTime -P |
		Add-Member 'NoteProperty' LastWriteTimeUtc $f.LastWriteTimeUtc -P |
		Add-Member 'NoteProperty' MemberType $t.MemberType -P |
		Add-Member 'NoteProperty' MetadataToken $t.MetadataToken -P |
		Add-Member 'NoteProperty' Module $t.Module -P |
		Add-Member 'NoteProperty' Name $t.Name -P |
		Add-Member 'NoteProperty' Namespace $t.Namespace -P |
		Add-Member 'NoteProperty' Parent $f.Parent -P |
		Add-Member 'NoteProperty' ReflectedType $t.ReflectedType -P |
		Add-Member 'NoteProperty' Root $f.Root -P |
		Add-Member 'NoteProperty' StructLayoutAttribute $t.StructLayoutAttribute -P |
		Add-Member 'NoteProperty' TypeHandle $t.TypeHandle -P |
		Add-Member 'NoteProperty' TypeInitializer $t.TypeInitializer -P |
		Add-Member 'NoteProperty' UnderlyingSystemType $t.UnderlyingSystemType -P |
		Add-Member 'NoteProperty' PSChildName $f.PSChildName -P |
		Add-Member 'NoteProperty' PSDrive $f.PSDrive -P |
		Add-Member 'NoteProperty' PSIsContainer $f.PSIsContainer -P |
		Add-Member 'NoteProperty' PSParentPath $f.PSParentPath -P |
		Add-Member 'NoteProperty' PSPath $f.PSPath -P |
		Add-Member 'NoteProperty' PSProvider $f.PSProvider -P |
		Add-Member 'NoteProperty' BaseName $f.BaseName -P |
		Add-Member 'ScriptMethod' Clone {} -P |
		Add-Member 'ScriptMethod' CompareTo {} -P |
		Add-Member 'ScriptMethod' Contains {} -P |
		Add-Member 'ScriptMethod' CopyTo {} -P |
		Add-Member 'ScriptMethod' Create {} -P |
		Add-Member 'ScriptMethod' CreateObjRef {} -P |
		Add-Member 'ScriptMethod' CreateSubdirectory {} -P |
		Add-Member 'ScriptMethod' Delete {} -P |
		Add-Member 'ScriptMethod' EndsWith {} -P |
		Add-Member 'ScriptMethod' FindInterfaces {} -P |
		Add-Member 'ScriptMethod' FindMembers {} -P |
		Add-Member 'ScriptMethod' GetAccessControl {} -P |
		Add-Member 'ScriptMethod' GetArrayRank {} -P |
		Add-Member 'ScriptMethod' GetConstructor {} -P |
		Add-Member 'ScriptMethod' GetConstructors {} -P |
		Add-Member 'ScriptMethod' GetCustomAttributes {} -P |
		Add-Member 'ScriptMethod' GetDefaultMembers {} -P |
		Add-Member 'ScriptMethod' GetDirectories {} -P |
		Add-Member 'ScriptMethod' GetElementType {} -P |
		Add-Member 'ScriptMethod' GetEnumerator {} -P |
		Add-Member 'ScriptMethod' GetEvent {} -P |
		Add-Member 'ScriptMethod' GetEvents {} -P |
		Add-Member 'ScriptMethod' GetField {} -P |
		Add-Member 'ScriptMethod' GetFields {} -P |
		Add-Member 'ScriptMethod' GetFiles {} -P |
		Add-Member 'ScriptMethod' GetFileSystemInfos {} -P |
		Add-Member 'ScriptMethod' GetGenericArguments {} -P |
		Add-Member 'ScriptMethod' GetGenericParameterConstraints {} -P |
		Add-Member 'ScriptMethod' GetGenericTypeDefinition {} -P |
		Add-Member 'ScriptMethod' GetInterface {} -P |
		Add-Member 'ScriptMethod' GetInterfaceMap {} -P |
		Add-Member 'ScriptMethod' GetInterfaces {} -P |
		Add-Member 'ScriptMethod' GetLifetimeService {} -P |
		Add-Member 'ScriptMethod' GetMember {} -P |
		Add-Member 'ScriptMethod' GetMembers {} -P |
		Add-Member 'ScriptMethod' GetMethod {} -P |
		Add-Member 'ScriptMethod' GetMethods {} -P |
		Add-Member 'ScriptMethod' GetNestedType {} -P |
		Add-Member 'ScriptMethod' GetNestedTypes {} -P |
		Add-Member 'ScriptMethod' GetObjectData {} -P |
		Add-Member 'ScriptMethod' GetProperties {} -P |
		Add-Member 'ScriptMethod' GetProperty {} -P |
		Add-Member 'ScriptMethod' GetTypeCode {} -P |
		Add-Member 'ScriptMethod' IndexOf {} -P |
		Add-Member 'ScriptMethod' IndexOfAny {} -P |
		Add-Member 'ScriptMethod' InitializeLifetimeService {} -P |
		Add-Member 'ScriptMethod' Insert {} -P |
		Add-Member 'ScriptMethod' InvokeMember {} -P |
		Add-Member 'ScriptMethod' IsAssignableFrom {} -P |
		Add-Member 'ScriptMethod' IsDefined {} -P |
		Add-Member 'ScriptMethod' IsInstanceOfType {} -P |
		Add-Member 'ScriptMethod' IsNormalized {} -P |
		Add-Member 'ScriptMethod' IsSubclassOf {} -P |
		Add-Member 'ScriptMethod' LastIndexOf {} -P |
		Add-Member 'ScriptMethod' LastIndexOfAny {} -P |
		Add-Member 'ScriptMethod' MakeArrayType {} -P |
		Add-Member 'ScriptMethod' MakeByRefType {} -P |
		Add-Member 'ScriptMethod' MakeGenericType {} -P |
		Add-Member 'ScriptMethod' MakePointerType {} -P |
		Add-Member 'ScriptMethod' MoveTo {} -P |
		Add-Member 'ScriptMethod' Normalize {} -P |
		Add-Member 'ScriptMethod' PadLeft {} -P |
		Add-Member 'ScriptMethod' PadRight {} -P |
		Add-Member 'ScriptMethod' Refresh {} -P |
		Add-Member 'ScriptMethod' Remove {} -P |
		Add-Member 'ScriptMethod' Replace {} -P |
		Add-Member 'ScriptMethod' SetAccessControl {} -P |
		Add-Member 'ScriptMethod' Split {} -P |
		Add-Member 'ScriptMethod' StartsWith {} -P |
		Add-Member 'ScriptMethod' Substring {} -P |
		Add-Member 'ScriptMethod' ToCharArray {} -P |
		Add-Member 'ScriptMethod' ToLower {} -P |
		Add-Member 'ScriptMethod' ToLowerInvariant {} -P |
		Add-Member 'ScriptMethod' ToUpper {} -P |
		Add-Member 'ScriptMethod' ToUpperInvariant {} -P |
		Add-Member 'ScriptMethod' Trim {} -P |
		Add-Member 'ScriptMethod' TrimEnd {} -P |
		Add-Member 'ScriptMethod' TrimStart {} -P |
		Add-Member 'NoteProperty' Chars $s.Chars -P
	}


	if ( "Add-Member" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "Compare-Object" -eq $_cmdlet )
	{
		$global:_dummy = (Compare-Object 1 2)[0]
	}


	if ( "ConvertFrom-SecureString" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "ConvertTo-SecureString" -eq $_cmdlet )
	{
		$global:_dummy = convertto-securestring "P@ssW0rD!" -asplaintext -force
	}


	if ( "ForEach-Object" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "Get-Acl" -eq $_cmdlet )
	{
		$global:_dummy = Get-Acl
	}


	if ( "Get-Alias" -eq $_cmdlet )
	{
		$global:_dummy = (Get-Alias)[0]
	}


	if ( "Get-AuthenticodeSignature" -eq $_cmdlet )
	{
		$global:_dummy = Get-AuthenticodeSignature $PSHOME\powershell.exe
	}


	if ( "Get-ChildItem" -eq $_cmdlet )
	{
		$global:_dummy = $global:_forgci
	}


	if ( "Get-Command" -eq $_cmdlet )
	{
		$global:_dummy = @(iex $str[$i + 1])[0]
	}


	if ( "Get-Content" -eq $_cmdlet )
	{
		$global:_dummy = (type $PSHOME\profile.ps1)[0]
	}


	if ( "Get-Credential" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "Get-Culture" -eq $_cmdlet )
	{
		$global:_dummy = Get-Culture
	}


	if ( "Get-Date" -eq $_cmdlet )
	{
		$global:_dummy = Get-Date
	}


	if ( "Get-Event" -eq $_cmdlet )
	{
		$global:_dummy = (Get-Event)[0]
	}


	if ( "Get-EventLog" -eq $_cmdlet )
	{
		$global:_dummy = Get-EventLog Windows` PowerShell -Newest 1
	}


	if ( "Get-ExecutionPolicy" -eq $_cmdlet )
	{
		$global:_dummy = Get-ExecutionPolicy
	}


	if ( "Get-Help" -eq $_cmdlet )
	{
		$global:_dummy = Get-Help Add-Content
	}


	if ( "Get-History" -eq $_cmdlet )
	{
		$global:_dummy = Get-History -Count 1
	}


	if ( "Get-Host" -eq $_cmdlet )
	{
		$global:_dummy = Get-Host
	}


	if ( "Get-Item" -eq $_cmdlet )
	{
		$global:_dummy = $global:_forgci
	}


	if ( "Get-ItemProperty" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "Get-Location" -eq $_cmdlet )
	{
		$global:_dummy = Get-Location
	}


	if ( "Get-Member" -eq $_cmdlet )
	{
		$global:_dummy = (1|Get-Member)[0]
	}


	if ( "Get-Module" -eq $_cmdlet )
	{
		$global:_dummy = (Get-Module)[0]
	}


	if ( "Get-PfxCertificate" -eq $_cmdlet )
	{
		$global:_dummy = $null
	}


	if ( "Get-Process" -eq $_cmdlet )
	{
		$global:_dummy = ps powershell
	}


	if ( "Get-PSBreakpoint" -eq $_cmdlet )
	{
		$global:_dummy =
		Add-Member -InputObject (New-Object PSObject) 'NoteProperty' Action '' -P |
		Add-Member 'NoteProperty' Command '' -P |
		Add-Member 'NoteProperty' Enabled '' -P |
		Add-Member 'NoteProperty' HitCount '' -P |
		Add-Member 'NoteProperty' Id '' -P |
		Add-Member 'NoteProperty' Script '' -P
	}


	if ( "Get-PSCallStack" -eq $_cmdlet )
	{
		$global:_dummy = Get-PSCallStack
	}


	if ( "Get-PSDrive" -eq $_cmdlet )
	{
		$global:_dummy = Get-PSDrive Function
	}


	if ( "Get-PSProvider" -eq $_cmdlet )
	{
		$global:_dummy = Get-PSProvider FileSystem
	}


	if ( "Get-PSSnapin" -eq $_cmdlet )
	{
		$global:_dummy = Get-PSSnapin Microsoft.PowerShell.Core
	}


	if ( "Get-Service" -eq $_cmdlet )
	{
		$global:_dummy = (Get-Service)[0]
	}


	if ( "Get-TraceSource" -eq $_cmdlet )
	{
		$global:_dummy = Get-TraceSource AddMember
	}


	if ( "Get-UICulture" -eq $_cmdlet )
	{
		$global:_dummy = Get-UICulture
	}


	if ( "Get-Variable" -eq $_cmdlet )
	{
		$global:_dummy = Get-Variable _
	}


	if ( "Get-WmiObject" -eq $_cmdlet )
	{
		$global:_dummy = @(iex $str[$i + 1])[0]
	}


	if ( "Group-Object" -eq $_cmdlet )
	{
		$global:_dummy = 1 | group
	}


	if ( "Measure-Command" -eq $_cmdlet )
	{
		$global:_dummy = Measure-Command {}
	}


	if ( "Measure-Object" -eq $_cmdlet )
	{
		$global:_dummy = Measure-Object
	}


	if ( "New-PSDrive" -eq $_cmdlet )
	{
		$global:_dummy = Get-PSDrive Alias
	}


	if ( "New-TimeSpan" -eq $_cmdlet )
	{
		$global:_dummy = New-TimeSpan
	}


	if ( "Resolve-Path" -eq $_cmdlet )
	{
		$global:_dummy = $PWD
	}


	if ( "Select-String" -eq $_cmdlet )
	{
		$global:_dummy = " " | Select-String " "
	}


	if ( "Set-Date" -eq $_cmdlet )
	{
		$global:_dummy = Get-Date
	}

	if ( $property -ne $null)
	{
		foreach ( $name in $property.Split(";", "RemoveEmptyEntries" -as [System.StringSplitOptions]) )
		{
			$global:_dummy = @($global:_dummy.$name)[0]
		}
	}
}



function TabExpansion {
	# This is the default function to use for tab expansion. It handles simple
	# member expansion on variables, variable name expansion and parameter completion
	# on commands. It doesn't understand strings so strings containing ; | ( or { may
	# cause expansion to fail.

	param($line, $lastWord)

	& {
		# Helper function to write out the matching set of members. It depends
		# on dynamic scoping to get $_base, _$expression and $_pat
		function Write-Members ($sep = '.')
		{

			# evaluate the expression to get the object to examine...
			Invoke-Expression ('$_val=' + $_expression)

			if ( $_expression -match '^\$global:_dummy' )
			{
				$temp = $_expression -replace '^\$global:_dummy(.*)','$1'
				$_expression = '$_' + $temp
			}


			$_method = [Management.Automation.PSMemberTypes] `
			'Method,CodeMethod,ScriptMethod,ParameterizedProperty'

			if ($sep -eq '.')
			{
				$members = 
				(
					[Object[]](Get-Member -InputObject $_val.PSextended $_pat) + 
					[Object[]](Get-Member -InputObject $_val.PSadapted $_pat) + 
					[Object[]](Get-Member -InputObject $_val.PSbase $_pat)
				)
				if ( $_val -is [Hashtable] )
				{
					[Microsoft.PowerShell.Commands.MemberDefinition[]]$_keys = $null
					foreach ( $_name in $_val.Keys )
					{
						$_keys += `
						New-Object Microsoft.PowerShell.Commands.MemberDefinition `
						[int],$_name,"Property",0
					}

					$members += [Object[]]$_keys | ? { $_.Name -like $_pat }
				}

				foreach ($_m in $members | sort membertype,name -Unique)
				{
					if ($_m.MemberType -band $_method)
					{
						# Return a method...
						$_base + $_expression + $sep + $_m.name + '('
					}
					else {
						# Return a property...
						$_base + $_expression + $sep + $_m.name
					}
				}
			}

			else
			{
				foreach ($_m in Get-Member -Static -InputObject $_val $_pat |
					Sort-Object membertype,name)
				{
					if ($_m.MemberType -band $_method)
					{
						# Return a method...
						$_base + $_expression + $sep + $_m.name + '('
					}
					else {
						# Return a property...
						$_base + $_expression + $sep + $_m.name
					}
				}
			}
		}

		switch ([int]$line[-1])
		{
			# Ctrl+D several date/time formats
			4 {
				"[DateTime]::Now"
				[DateTime]::Now
				[DateTime]::Now.ToString("yyyyMMdd")
				[DateTime]::Now.ToString("MMddyyyy")
				[DateTime]::Now.ToString("yyyyMMddHHmmss")
				[DateTime]::Now.ToString("MMddyyyyHHmmss")
				'd f g m o r t u y'.Split(" ") | % { [DateTime]::Now.ToString($_) }
				break;
			}

			# Ctrl+P hand-operated pop from command buffer stack
			16 {
				$_base = $lastword.SubString(0, $lastword.Length-1)
				$_buf = $global:_cmdstack.Pop()
				if ( $_buf.Contains("'") )
				{
					$line = ($line.SubString(0, $line.Length-1) + $_buf) -replace '([[\]\(\)+{}?~%])','{$1}'
					[System.Windows.Forms.SendKeys]::SendWait("{Esc}$line")
				}
				else {
					$_base + $_buf
				}
				break;
			}

			# Ctrl+R $Host.UI.RawUI.
			18 {
				'$Host.UI.RawUI.'
				'$Host.UI.RawUI'
				break;
			}

			# Ctrl+V paste clipboard
			22 {
				$_base = $lastword.SubString(0, $lastword.Length-1)
				$global:_clip = New-Object System.Windows.Forms.TextBox
				$global:_clip.Multiline = $true
				$global:_clip.Paste()
				$line = ($line.SubString(0, $line.Length-1) + $global:_clip.Text) -replace '([[\]\(\)+{}?~%])','{$1}'
				[System.Windows.Forms.SendKeys]::SendWait("{Esc}$line")
				break;
			}
		}

		switch -regex ($lastWord)
		{

			# Handle property and method expansion at '$_'
			'(^.*)(\$_\.)(\w*)$' {
				$_base = $matches[1]
				$_expression = '$global:_dummy'
				$_pat = $matches[3] + '*'
				$global:_dummy = $null
				Get-PipeLineObject
				if ( $global:_dummy -eq $null )
				{

					if ( $global:_exp -match '^\$.*\(.*$' )
					{
						$type = ( iex $_exp.Split("(")[0] ).OverloadDefinitions[0].Split(" ")[0] -replace '\[[^\[\]]*\]$' -as [type]

						if ( $_expression -match '^\$global:_dummy' )
						{
							$temp = $_expression -replace '^\$global:_dummy(.*)','$1'
							$_expression = '$_' + $temp
						}

						foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
						{
							if ($_m.MemberType -eq "Method")
							{
								$_base + $_expression + '.' + $_m.name + '('
							}
							else {
								$_base + $_expression + '.' + $_m.name
							}
						}
						break;
					}
					elseif ( $global:_exp -match '^\[.*\:\:.*\(.*$' )
					{
						$tname, $mname = $_exp.Split(":(", "RemoveEmptyEntries"-as [System.StringSplitOptions])[0,1]
						$type = @(iex ($tname + '.GetMember("' + $mname + '")'))[0].ReturnType.FullName -replace '\[[^\[\]]*\]$' -as [type]

						if ( $_expression -match '^\$global:_dummy' )
						{
							$temp = $_expression -replace '^\$global:_dummy(.*)','$1'
							$_expression = '$_' + $temp
						}

						foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
						{
							if ($_m.MemberType -eq "Method")
							{
								$_base + $_expression + '.' + $_m.name + '('
							}
							else {
								$_base + $_expression + '.' + $_m.name
							}
						}
						break;
					}
					elseif ( $global:_exp -match '^(\$\w+(\[[0-9,\.]+\])*(\.\w+(\[[0-9,\.]+\])*)*)$' )
					{
						$global:_dummy = @(iex $Matches[1])[0]
					}
					else
					{
						$global:_dummy = $global:_mix
					}
				}

				Write-Members
				break;
			}

			# Handle property and method expansion rooted at variables...
			# e.g. $a.b.<tab>
			'(^.*)(\$(\w|\.)+)\.(\w*)$' {
				$_base = $matches[1]
				$_expression = $matches[2]
				[void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
				$_pat = $matches[4] + '*'
				if ( $_expression -match '^\$_\.' )
				{
					$_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
				}
				Write-Members
				break;
			}

			# Handle simple property and method expansion on static members...
			# e.g. [datetime]::n<tab>
			'(^.*)(\[(\w|\.)+\])\:\:(\w*)$' {
				$_base = $matches[1]
				$_expression = $matches[2]
				$_pat = $matches[4] + '*'
				Write-Members '::'
				break;
			}

			# Handle complex property and method expansion on static members
			# where there are intermediate properties...
			# e.g. [datetime]::now.d<tab>
			'(^.*)(\[(\w|\.)+\]\:\:(\w+\.)+)(\w*)$' {
				$_base = $matches[1] # everything before the expression
				$_expression = $matches[2].TrimEnd('.') # expression less trailing '.'
				$_pat = $matches[5] + '*' # the member to look for...
				Write-Members
				break;
			}

			# Handle variable name expansion...
			'(^.*\$)(\w+)$' {
				$_prefix = $matches[1]
				$_varName = $matches[2]
				foreach ($_v in Get-ChildItem ('variable:' + $_varName + '*'))
				{
					$_prefix + $_v.name
				}
				break;
			}

			# Handle env&function drives variable name expansion...
			'(^.*\$)(.*\:)(\w+)$' {
				$_prefix = $matches[1]
				$_drive = $matches[2]
				$_varName = $matches[3]
				if ($_drive -eq "env:" -or $_drive -eq "function:")
				{
					foreach ($_v in Get-ChildItem ($_drive + $_varName + '*'))
					{
						$_prefix + $_drive + $_v.name
					}
				}
				break;
			}

			# Handle array's element property and method expansion
			# where there are intermediate properties...
			# e.g. foo[0].n.b<tab>
			'(^.*)(\$((\w+\.)|(\w+(\[(\w|,)+\])+\.))+)(\w*)$'
			{
				$_base = $matches[1]
				$_expression = $matches[2].TrimEnd('.')
				$_pat = $Matches[8] + '*'
				[void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
				if ( $_expression -match '^\$_\.' )
				{
					$_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
				}
				Write-Members
				break;
			}

			# Handle property and method expansion rooted at type object...
			# e.g. [System.Type].a<tab>
			'(^\[(\w|\.)+\])\.(\w*)$'
			{
				if ( $(iex $Matches[1]) -isnot [System.Type] ) { break; }
				$_expression = $Matches[1]
				$_pat = $Matches[$matches.Count-1] + '*'
				Write-Members
				break;
			}

			# Handle complex property and method expansion on type object members
			# where there are intermediate properties...
			# e.g. [datetime].Assembly.a<tab>
			'^(\[(\w|\.)+\]\.(\w+\.)+)(\w*)$' {
				$_expression = $matches[1].TrimEnd('.') # expression less trailing '.'
				$_pat = $matches[4] + '*' # the member to look for...
				if ( $(iex $_expression) -eq $null ) { break; }
				Write-Members
				break;
			}

			# Handle property and method expansion rooted at close parenthes...
			# e.g. (123).a<tab>
			'^(.*)\)((\w|\.)*)\.(\w*)$' {
				$_base = $Matches[1] + ")"
				if ( $matches[3] -eq $null) { $_expression = '[System.Type]' }
				else { $_expression = '[System.Type]' + $Matches[2] }
				$_pat = $matches[4] + '*'
				iex "$_expression | Get-Member $_pat | sort MemberType,Name" |
				% {
					if ( $_.MemberType -like "*Method*" -or $_.MemberType -like "*Parameterized*" ) { $parenthes = "(" }
					if ( $Matches[2] -eq "" ) { $_base + "." + $_.Name + $parenthes }
					else { $_base + $Matches[2] + "." + $_.Name + $parenthes }
				}
				break;
			}

			# Handle .NET type name expansion ...
			# e.g. [Microsoft.PowerShell.Com<tab>
			'^\[(\w+(\.\w*)*)$' {
				$_opt = $matches[1] + '*'
				if ( $_opt -eq "*" )
				{
					$_TypeAccelerators -like $_opt -replace '^(.*)$', '[$1]'
				}
				else
				{
					$_TypeAccelerators -like $_opt -replace '^(.*)$', '[$1]'
					Write-ClassNames $_TypeNames_System ($_opt.Split(".").Count-1) '['
					Write-ClassNames $_TypeNames ($_opt.Split(".").Count-1) '['
				}
				break;
			}

			# Handle file/directory name which contains $env: variable
			# e.g.  $env:windir\<tab>
			'^\$(env:)?\w+([\\/][^\\/]*)*$' {
				$path = iex ('"' + $Matches[0] + '"')
				if ( $Matches[2].Length -gt 1 )
				{
					$parent = Split-Path $path -Parent
					$leaf = (Split-Path $path -Leaf) + '*'
				}
				else
				{
					$parent = $path
					$leaf = '*'
				}
				if ( Test-Path $parent )
				{
					$i = $Matches[0].LastIndexOfAny("/\")
					$_base = $Matches[0].Substring(0,$i + 1)
					[IO.Directory]::GetFileSystemEntries( $parent, $leaf ) | % { $_base + ($_.Split("\/")[-1] -replace '([\$\s&])','`$1' -replace '([[\]])', '````$1') }
				}
			}

			# Handle file glob expansion ...
			# e.g. *.txt~about*@<tab>
			'^(\^?([^~]+))(~(.*))*@$' {
				if ( $Matches[1] -notlike "^*" )
				{
					$include = $Matches[2] -replace '``','`'
					if ( $Matches[3] )
					{
						$exclude = $Matches[3].Split("~", "RemoveEmptyEntries" -as [System.StringSplitOptions]) -replace '``','`'
					}
				}
				else
				{
					$include = "*"
					$exclude = $Matches[2] -replace '``','`'
				}
				$fse = [IO.Directory]::GetFileSystemEntries($PWD)
				$fse = $fse -replace '.*[\\/]([^/\\]*)$','$1'
				% -in ($fse -like $include) { $fse = $_; $exclude | % { $fse = $fse -notlike $_ } }
				$fse = $fse -replace '^.*\s.*$', ('"$0"')
				$fse = $fse -replace '([\[\]])', '````$1' -replace '^.*([\[\]]).*$', ('"$0"')
				$fse = $fse -replace '""', '"'
				$OFS = ", "; "$fse"
				$OFS = ", "; "* -Filter $include " + $(if($exclude){"-Exclude $exclude"})
				$Matches[0].Substring(0, $Matches[0].Length-1)
				break;
			}

			# Handle command buffer stack...
			'(.*);(.?)$' {
				$_base = $Matches[1]
				if ( $Matches[2] -eq ":" -or $Matches[2] -eq "," )
				{
					if ( $_cmdstack.Count -gt 0 )
					{
						$_buf = $global:_cmdstack.Pop()
						if ( $_buf.Contains("'") )
						{
							$line = ($line.SubString(0, $line.Length-1) + $_buf) -replace '([[\]\(\)+{}?~%])','{$1}'
							[System.Windows.Forms.SendKeys]::SendWait("{Esc}$line")
						}
						else {
							$_base + $_buf
						}
					}
					else
					{
						""
					}
				}
				elseif ( $Matches[2] -eq "" )
				{
					$global:_cmdstack.Push($line.SubString(0,$line.Length-1))
					[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
				}
			}

			# Do completion on parameters...
			'^-([\w0-9]*)' {
				$_pat = $matches[1] + '*'

				# extract the command name from the string
				# first split the string into statements and pipeline elements
				# This doesn't handle strings however.
				$_cmdlet = [regex]::Split($line, '[|;=]')[-1]

				#  Extract the trailing unclosed block e.g. ls | foreach { cp
				if ($_cmdlet -match '\{([^\{\}]*)$')
				{
					$_cmdlet = $matches[1]
				}

				# Extract the longest unclosed parenthetical expression...
				if ($_cmdlet -match '\(([^()]*)$')
				{
					$_cmdlet = $matches[1]
				}

				# take the first space separated token of the remaining string
				# as the command to look up. Trim any leading or trailing spaces
				# so you don't get leading empty elements.
				$_cmdlet = $_cmdlet.Trim().Split()[0]

				# now get the info object for it...
				$_cmdlet = @(Get-Command -type 'All' $_cmdlet)[0]

				# loop resolving aliases...
				while ($_cmdlet.CommandType -eq 'alias')
				{
					$_cmdlet = @(Get-Command -type 'All' $_cmdlet.Definition)[0]
				}

				if ( $_cmdlet.name -eq "powershell.exe" )
				{
					if ( $global:_PSexeOption )
					{
						$global:_PSexeOption -like "-$_pat" -replace '^(-[^,]+).*$', '$1' | sort
					}
					else
					{
						(							$global:_PSexeOption = powershell.exe -?) -like "-$_pat" -replace '^(-[^,]+).*$', '$1' | sort
					}
					break;
				}

				if ( $_cmdlet.CommandType -eq "Cmdlet" )
				{
					# expand the parameter sets and emit the matching elements
					foreach ($_n in $_cmdlet.ParameterSets |
						Select-Object -expand parameters | Sort-Object -Unique name)
					{
						$_n = $_n.name
						if ($_n -like $_pat) { '-' + $_n }
					}
					break;
				}
				elseif ( "ExternalScript", "Function", "Filter" -contains $_cmdlet.CommandType )
				{
					if ( $_cmdlet.CommandType -eq "ExternalScript" )
					{
						$_fsr = New-Object IO.StreamReader $_cmdlet.Definition
						$_def = "Function _Dummy { $($_fsr.ReadToEnd()) }"
						$_fsr.Close()
						iex $_def
						$_cmdlet = "_Dummy"
					}

					if ( ((gi "Function:$_cmdlet").Definition -replace '\n').Split("{")[0] -match 'param\((.*\))\s*[;\.&a-zA-Z]*\s*$' )
					{
						(							(								(									$Matches[1].Split('$', "RemoveEmptyEntries" -as [System.StringSplitOptions]) -replace `
									'^(\w+)(.*)','$1' ) -notmatch '^\s+$' ) -notmatch '^\s*\[.*\]\s*$' ) -like $_pat | sort | % { '-' + $_ }
					}
					break;
				}
				elseif ( $line -match 'switch\s+(-\w+\s+)*-(\w*)$')
				{
					$_pat = $Matches[2] + '*'
					"regex", "wildcard", "exact", "casesensitive", "file" -like $_pat -replace '^(.*)$', '-$1'
					break;
				}
				elseif ( $_cmdlet -eq $null )
				{
					"-and", "-as", "-band", "-bnot", "-bor", "-bxor", "-ccontains", "-ceq", "-cge", "-cgt", "-cle", "-clike", "-clt",
					"-cmatch", "-cne", "-cnotcontains", "-cnotlike", "-cnotmatch", "-contains", "-creplace", "-csplit", "-eq", "-f", "-ge",
					"-gt", "-icontains", "-ieq", "-ige", "-igt", "-ile", "-ilike", "-ilt", "-imatch", "-ine", "-inotcontains", "-inotlike",
					"-inotmatch", "-ireplace", "-is", "-isnot", "-isplit", "-join", "-le", "-like", "-lt", "-match", "-ne", "-not", "-notcontains", 
					"-notlike", "-notmatch", "-or", "-replace", "-split", "-xor" -like "-$_pat"
				}
				break;
			}


			# Tab complete against history either #<pattern> or #<id>
			'^#(\w*)' {
				$_pattern = $matches[1]
				if ($_pattern -match '^[0-9]+$')
				{
					Get-History -ea SilentlyContinue -Id $_pattern | Foreach { $_.CommandLine } 
				}
				else
				{
					$_pattern = '*' + $_pattern + '*'
					Get-History | Sort-Object -Descending Id| Foreach { $_.CommandLine } | where { $_ -like $_pattern }
				}
				break;
			}

			# try to find a matching command...
			default {

				$lastex = [regex]::Split($line, '[|;]')[-1]
				if ( $lastex -match '^\s*(\$\w+(\[[0-9,]+\])*(\.\w+(\[[0-9,]+\])*)*)\s*=\s+(("\w+"\s*,\s+)*)"\w+"\s*-as\s+$' )
				{
					if ( $Matches[6] -ne $nul )
					{
						$brackets = "[]"
					}
					'['+ $global:_enum + $brackets + ']'
					break;
				}


				if ( $lastex -match '^\s*(\$\w+(\[[0-9,]+\])*(\.\w+(\[[0-9,]+\])*)*)\s*=\s+(("\w+"\s*,\s+)*)\s*(\w*)$' )
				{
					$_pat = $Matches[7] + '*'

					$_type = @(iex $Matches[1])[0].GetType()
					if ( $_type.IsEnum )
					{
						$global:_enum = $_type.FullName
						[Enum]::GetValues($_type) -like $_pat -replace '^(.*)$','"$1"'
						break;
					}
				}

				$lastex = [regex]::Split($line, '[|;=]')[-1]
				if ($lastex -match '[[$].*\w+\(.*-as\s*$')
				{
					'['+ $global:_enum + ']'
				}
				elseif ( $lastex -match '([[$].*(\w+))\((.*)$' )
				#elseif ( $lastex -match '([[$].*(\w+))\(([^)]*)$' )
				{
					$_method = $Matches[1]

					if ( $Matches[3] -match "(.*)((`"|')(\w+,)+(\w*))$" )
					{
						$continuous = $true
						$_opt = $Matches[5] + '*'
						$_base = $Matches[2].TrimStart('"') -replace '(.*,)\w+$','$1'
						$position = $Matches[1].Split(",").Length
					}
					else
					{
						$continuous = $false
						$_opt = ($Matches[3].Split(',')[-1] -replace '^\s*','') + "*"
						$position = $Matches[3].Split(",").Length
					}

					if ( ($_mdefs = iex ($_method + ".OverloadDefinitions")) -eq $null )
					{
						$tname, $mname = $_method.Split(":", "RemoveEmptyEntries" -as [System.StringSplitOptions])
						$_mdefs = iex ($tname + '.GetMember("' + $mname + '") | % { $_.ToString() }')
					}

					foreach ( $def in $_mdefs )
					{
						[void] ($def -match '\((.*)\)')
						foreach ( $param in [regex]::Split($Matches[1], ', ')[$position - 1] )
						{
							if ($param -eq $null -or $param -eq "")
							{
								continue;
							}
							$type = $param.split()[0]

							if ( $type -like '*`[*' -or $type -eq "Params" -or $type -eq "" )
							{
								continue;
							}
							$fullname = @($_typenames -like "*$type*")
							foreach ( $name in $fullname )
							{
								if ( $continuous -eq $true -and ( $name -as [System.Type] ).IsEnum )
								{
									$output = [Enum]::GetValues($name) -like $_opt -replace '^(.*)$',($_base + '$1')
									$output | sort
								}
								elseif ( ( $name -as [System.Type] ).IsEnum ) 
								{
									$global:_enum = $name
									$output = [Enum]::GetValues($name) -like $_opt -replace '^(.*)$','"$1"'
									$output | sort
								}
							}
						}
					}
					if ( $output -ne $null )
					{
						break;
					}
				}

				if ( $line -match '(function|filter)\s+(\w*)$')
				{
					$_pat = 'function:\' + $Matches[2] + '*'
					Get-ChildItem $_pat| % { $_.Name }
					break;
				}

				if ( $line[-1] -eq " " )
				{
					$_cmdlet = $line.TrimEnd(" ").Split(" |(;={")[-1]

					# now get the info object for it...
					$_cmdlet = @(Get-Command -type 'cmdlet,alias,function' $_cmdlet)[0]

					# loop resolving aliases...
					while ($_cmdlet.CommandType -eq 'alias')
					{
						$_cmdlet = @(Get-Command -type 'cmdlet,alias,function' $_cmdlet.Definition)[0]
					}

					if ( "Set-ExecutionPolicy" -eq $_cmdlet.Name )
					{
						"Unrestricted", "RemoteSigned", "AllSigned", "Restricted", "Default" | sort
						break;
					}

					if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name )
					{
						Get-TraceSource | % { $_.Name } | sort -Unique
						break;
					}

					if ( "New-Object" -eq $_cmdlet.Name )
					{
						$_TypeAccelerators
						break;
					}

					if ( $_cmdlet.Noun -like "*WMI*" )
					{
						$_WMIClasses
						break;
					}

					if ( "Get-Process" -eq $_cmdlet.Name )
					{
						Get-Process | % { $_.Name } | sort
						break;
					}

					if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" -contains $_cmdlet.Name )
					{
						if ( $global:_snapin -ne $null )
						{
							$global:_snapin
							break;
						}
						else
						{
							$global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
							$global:_snapin
							break;
						}
					}

					if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
						-contains $_cmdlet.Name -and "Name" )
					{
						Get-PSDrive | sort
						break;
					}

					if ( "Get-Eventlog" -eq $_cmdlet.Name )
					{
						Get-EventLog -List | % { $_base + ($_.Log -replace '\s','` ') }
						break;
					}

					if ( "Get-Help" -eq $_cmdlet.Name -or "help" -eq $_cmdlet.Name -or "man" -eq $_cmdlet.Name )
					{
						Get-Help -Category all | % { $_.Name } | sort -Unique
						break;
					}

					if ( "Get-Service", "Restart-Service", "Resume-Service",
						"Start-Service", "Stop-Service", "Suspend-Service" `
						-contains $_cmdlet.Name )
					{
						Get-Service | sort Name | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Get-Command" -eq $_cmdlet.Name )
					{
						Get-Command -CommandType All | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
						"ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
						-contains $_cmdlet.Name )
					{
						Get-PipeLineObject
						$_dummy | Get-Member -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Clear-Variable", "Get-Variable", "New-Variable", "Remove-Variable", "Set-Variable" -contains $_cmdlet.Name )
					{
						Get-Variable -Scope Global | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-Alias", "New-Alias", "Set-Alias" -contains $_cmdlet.Name )
					{
						Get-Alias | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}
				}

				if ( $line[-1] -eq " " )
				{
					# extract the command name from the string
					# first split the string into statements and pipeline elements
					# This doesn't handle strings however.
					$_cmdlet = [regex]::Split($line, '[|;=]')[-1]

					#  Extract the trailing unclosed block e.g. ls | foreach { cp
					if ($_cmdlet -match '\{([^\{\}]*)$')
					{
						$_cmdlet = $matches[1]
					}

					# Extract the longest unclosed parenthetical expression...
					if ($_cmdlet -match '\(([^()]*)$')
					{
						$_cmdlet = $matches[1]
					}

					# take the first space separated token of the remaining string
					# as the command to look up. Trim any leading or trailing spaces
					# so you don't get leading empty elements.
					$_cmdlet = $_cmdlet.Trim().Split()[0]

					# now get the info object for it...
					$_cmdlet = @(Get-Command -type 'Application' $_cmdlet)[0]

					if ( $_cmdlet.Name -eq "powershell.exe" )
					{
						"-PSConsoleFile", "-Version", "-NoLogo", "-NoExit", "-Sta", "-NoProfile", "-NonInteractive",
						"-InputFormat", "-OutputFormat", "-EncodedCommand", "-File", "-Command" | sort
						break;
					}
					if ( $_cmdlet.Name -eq "fsutil.exe" )
					{
						"behavior query", "behavior set", "dirty query", "dirty set", 
						"file findbysid", "file queryallocranges", "file setshortname", "file setvaliddata", "file setzerodata", "file createnew", 
						"fsinfo drives", "fsinfo drivetype", "fsinfo volumeinfo", "fsinfo ntfsinfo", "fsinfo statistics", 
						"hardlink create", "objectid query", "objectid set", "objectid delete", "objectid create",
						"quota disable", "quota track", "quota enforce", "quota violations", "quota modify", "quota query",
						"reparsepoint query", "reparsepoint delete", "sparse setflag", "sparse queryflag", "sparse queryrange", "sparse setrange",
						"usn createjournal", "usn deletejournal", "usn enumdata", "usn queryjournal", "usn readdata", "volume dismount", "volume diskfree" | sort
						break;
					}
					if ( $_cmdlet.Name -eq "net.exe" )
					{
						"ACCOUNTS ", " COMPUTER ", " CONFIG ", " CONTINUE ", " FILE ", " GROUP ", " HELP ", 
						"HELPMSG ", " LOCALGROUP ", " NAME ", " PAUSE ", " PRINT ", " SEND ", " SESSION ", 
						"SHARE ", " START ", " STATISTICS ", " STOP ", " TIME ", " USE ", " USER ", " VIEW" | sort
						break;
					}
					if ( $_cmdlet.Name -eq "ipconfig.exe" )
					{
						"/?", "/all", "/renew", "/release", "/flushdns", "/displaydns",
						"/registerdns", "/showclassid", "/setclassid"
						break;
					}
				}

				if ( $line -match '\w+\s+(\w+(\.|[^\s\.])*)$' )
				{
					#$_opt = $Matches[1] + '*'
					$_cmdlet = $line.TrimEnd(" ").Split(" |(;={")[-2]

					$_opt = $Matches[1].Split(" ,")[-1] + '*'
					$_base = $Matches[1].Substring(0,$Matches[1].Length-$Matches[1].Split(" ,")[-1].length)


					# now get the info object for it...
					$_cmdlet = @(Get-Command -type 'cmdlet,alias,function' $_cmdlet)[0]

					# loop resolving aliases...
					while ($_cmdlet.CommandType -eq 'alias')
					{
						$_cmdlet = @(Get-Command -type 'cmdlet,alias,function' $_cmdlet.Definition)[0]
					}

					if ( "Set-ExecutionPolicy" -eq $_cmdlet.Name )
					{
						"Unrestricted", "RemoteSigned", "AllSigned", "Restricted", "Default" -like $_opt | sort
						break;
					}

					if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name )
					{
						Get-TraceSource -Name $_opt | % { $_.Name } | sort -Unique | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "New-Object" -eq $_cmdlet.Name )
					{
						$_TypeAccelerators -like $_opt
						Write-ClassNames $_TypeNames_System ($_opt.Split(".").Count-1)
						Write-ClassNames $_TypeNames ($_opt.Split(".").Count-1)
						break;
					}

					if ( $_cmdlet.Name -like "*WMI*" )
					{
						Write-ClassNames $_WMIClasses ($_opt.Split("_").Count-1) -sep '_'
						break;
					}

					if ( "Get-Process" -eq $_cmdlet.Name )
					{
						Get-Process $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" -contains $_cmdlet.Name )
					{
						if ( $global:_snapin -ne $null )
						{
							$global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
							break;
						}
						else
						{
							$global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
							$global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
							break;
						}
					}

					if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
						-contains $_cmdlet.Name -and "Name" )
					{
						Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-PSProvider" -eq $_cmdlet.Name )
					{
						Get-PSProvider -PSProvider $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}


					if ( "Get-Eventlog" -eq $_cmdlet.Name )
					{
						Get-EventLog -List | ? { $_.Log -like $_opt } | % { $_base + ($_.Log -replace '\s','` ') }
						break;
					}

					if ( "Get-Help" -eq $_cmdlet.Name -or "help" -eq $_cmdlet.Name -or "man" -eq $_cmdlet.Name )
					{
						Get-Help -Category all -Name $_opt | % { $_.Name } | sort -Unique
						break;
					}

					if ( "Get-Service", "Restart-Service", "Resume-Service",
						"Start-Service", "Stop-Service", "Suspend-Service" `
						-contains $_cmdlet.Name )
					{
						Get-Service -Name $_opt | sort Name | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Get-Command" -eq $_cmdlet.Name )
					{
						Get-Command -CommandType All -Name $_opt | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
						"ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
						-contains $_cmdlet.Name )
					{
						Get-PipeLineObject
						$_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Clear-Variable", "Get-Variable", "New-Variable", "Remove-Variable", "Set-Variable" -contains $_cmdlet.Name )
					{
						Get-Variable -Scope Global -Name $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-Alias", "New-Alias", "Set-Alias" -contains $_cmdlet.Name )
					{
						Get-Alias -Name $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}
				}

				if ( $line -match '(-(\w+))\s+([^-]*$)' )
				{

					$_param = $matches[2] + '*'
					$_opt = $Matches[3].Split(" ,")[-1] + '*'
					$_base = $Matches[3].Substring(0,$Matches[3].Length-$Matches[3].Split(" ,")[-1].length)

					$_cmdlet = [regex]::Split($line, '[|;=]')[-1]

					#  Extract the trailing unclosed block e.g. ls | foreach { cp
					if ($_cmdlet -match '\{([^\{\}]*)$')
					{
						$_cmdlet = $matches[1]
					}

					if ($_cmdlet -match '\(([^()]*)$')
					{
						$_cmdlet = $matches[1]
					}

					$_cmdlet = $_cmdlet.Trim().Split()[0]

					$_cmdlet = @(Get-Command -type 'cmdlet,alias,ExternalScript,Filter,Function' $_cmdlet)[0]

					while ($_cmdlet.CommandType -eq 'alias')
					{
						$_cmdlet = @(Get-Command -type 'cmdlet,alias,ExternalScript,Filter,Function' $_cmdlet.Definition)[0]
					}

					if ( $_param.TrimEnd("*") -eq "ea" -or $_param.TrimEnd("*") -eq "wa" )
					{
						"SilentlyContinue", "Stop", "Continue", "Inquire" |
						? { $_ -like $_opt } | sort -Unique
						break;
					}

					if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide" -contains $_cmdlet.Name `
						-and "groupBy" -like $_param )
					{
						Get-PipeLineObject
						$_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_.Name }
						break;
					}

					if ( $_param.TrimEnd("*") -eq "ev" -or $_param.TrimEnd("*") -eq "ov" -or
						"ErrorVariable" -like $_param -or "OutVariable" -like $_param)
					{
						Get-Variable -Scope Global -Name $_opt | % { $_.Name } | sort
						break;
					}

					if ( "Tee-Object" -eq $_cmdlet.Name -and "Variable" -like $_param )
					{
						Get-Variable -Scope Global -Name $_opt | % { $_.Name } | sort
						break;
					}

					if ( "Clear-Variable", "Get-Variable", "New-Variable", "Remove-Variable", "Set-Variable" -contains $_cmdlet.Name `
						-and "Name" -like $_param)
					{
						Get-Variable -Scope Global -Name $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Export-Alias", "Get-Alias", "New-Alias", "Set-Alias" -contains $_cmdlet.Name `
						-and "Name" -like $_param)
					{
						Get-Alias -Name $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Out-File","Export-CSV","Select-String","Export-Clixml" -contains $_cmdlet.Name `
						-and "Encoding" -like $_param)
					{
						"Unicode", "UTF7", "UTF8", "ASCII", "UTF32", "BigEndianUnicode", "Default", "OEM" |
						? { $_ -like $_opt } | sort -Unique
						break;
					}

					if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name `
						-and "Name" -like $_param)
					{
						Get-TraceSource -Name $_opt | % { $_.Name } | sort -Unique | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "New-Object" -like $_cmdlet.Name )
					{
						if ( "ComObject" -like $_param )
						{
							$_ProgID -like $_opt | % { $_ -replace '\s','` ' }
							break;
						}

						if ( "TypeName" -like $_param )
						{
							if ( $_opt -eq "*" )
							{
								$_TypeAccelerators -like $_opt
							}
							else
							{
								$_TypeAccelerators -like $_opt
								Write-ClassNames $_TypeNames_System ($_opt.Split(".").Count-1)
								Write-ClassNames $_TypeNames ($_opt.Split(".").Count-1)
							}
							break;
						}
					}

					if ( "New-Item" -eq $_cmdlet.Name )
					{
						if ( "ItemType" -like $_param )
						{
							"directory", "file" -like $_opt
							break;
						}
					}

					if ( "Get-Location", "Get-PSDrive", "Get-PSProvider", "New-PSDrive", "Remove-PSDrive" `
						-contains $_cmdlet.Name `
						-and "PSProvider" -like $_param )
					{
						Get-PSProvider -PSProvider $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-Location" -eq $_cmdlet.Name -and "PSDrive" -like $_param )
					{
						Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
						-contains $_cmdlet.Name -and "Name" -like $_param )
					{
						Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-Command" -eq $_cmdlet.Name -and "PSSnapin" -like $_param)
					{
						if ( $global:_snapin -ne $null )
						{
							$global:_snapin -like $_opt | % { $_base + $_ }
							break;
						}
						else
						{
							$global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
							$global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
							break;
						}
					}

					if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" `
						-contains $_cmdlet.Name -and "Name" -like $_param )
					{
						if ( $global:_snapin -ne $null )
						{
							$global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
							break;
						}
						else
						{
							$global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
							$global:_snapin -like $_opt | % { $_base + $_ }
							break;
						}
					}

					if ( "Clear-Variable", "Export-Alias", "Get-Alias", "Get-PSDrive", "Get-Variable", "Import-Alias",
						"New-Alias", "New-PSDrive", "New-Variable", "Remove-Variable", "Set-Alias", "Set-Variable" `
						-contains $_cmdlet.Name -and "Scope" -like $_param )
					{
						"Global", "Local", "Script" -like $_opt
						break;
					}

					if ( "Get-Process", "Stop-Process", "Wait-Process" -contains $_cmdlet.Name -and "Name" -like $_param )
					{
						Get-Process $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
						break;
					}

					if ( "Get-Eventlog" -eq $_cmdlet.Name -and "LogName" -like $_param )
					{
						Get-EventLog -List | ? { $_.Log -like $_opt } | % { $_base + ($_.Log -replace '\s','` ') }
						break;
					}

					if ( "Get-Help" -eq $_cmdlet.Name -or "help" -eq $_cmdlet.Name -or "man" -eq $_cmdlet.Name )
					{
						if ( "Name" -like $_param )
						{
							Get-Help -Category all -Name $_opt | % { $_.Name } | sort -Unique
							break;
						}
						if ( "Category" -like $_param )
						{
							"Alias", "Cmdlet", "Provider", "General", "FAQ",
							"Glossary", "HelpFile", "All" -like $_opt | sort | % { $_base + $_ }
							break;
						}
					}

					if ( "Get-Service", "Restart-Service", "Resume-Service",
						"Start-Service", "Stop-Service", "Suspend-Service" `
						-contains $_cmdlet.Name )
					{
						if ( "Name" -like $_param )
						{
							Get-Service -Name $_opt | sort Name | % { $_base + ($_.Name -replace '\s','` ') }
							break;
						}
						if ( "DisplayName" -like $_param )
						{
							Get-Service -Name $_opt | sort DisplayName | % { $_base + ($_.DisplayName -replace '\s','` ') }
							break;
						}
					}

					if ( "New-Service" -eq $_cmdlet.Name -and "dependsOn" -like $_param )
					{
						Get-Service -Name $_opt | sort Name | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Get-EventLog" -eq $_cmdlet.Name -and "EntryType" -like $_param )
					{
						"Error", "Information", "FailureAudit", "SuccessAudit", "Warning" -like $_opt | sort | % { $_base + $_ }
						break;
					}

					if ( "Get-Command" -eq $_cmdlet.Name -and "Name" -like $_param )
					{
						Get-Command -CommandType All -Name $_opt | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( $_cmdlet.Noun -like "*WMI*" )
					{
						if ( "Class" -like $_param )
						{
							Write-ClassNames $_WMIClasses ($_opt.Split("_").Count-1) -sep '_'
							break;
						}
					}

					if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
						"ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
						-contains $_cmdlet.Name -and "Property" -like $_param )
					{
						Get-PipeLineObject
						$_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
						break;
					}

					if ( "Select-Object" -eq $_cmdlet.Name )
					{
						if ( "ExcludeProperty" -like $_param )
						{
							Get-PipeLineObject
							$_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
							break;
						}

						if ( "ExpandProperty" -like $_param )
						{
							Get-PipeLineObject
							$_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_.Name }
							break;
						}
					}

					if ( "ExternalScript", "Function", "Filter" -contains $_cmdlet.CommandType )
					{
						if ( $_cmdlet.CommandType -eq "ExternalScript" )
						{
							$_fsr = New-Object IO.StreamReader $_cmdlet.Definition
							$_def = "Function _Dummy { $($_fsr.ReadToEnd()) }"
							$_fsr.Close()
							iex $_def
							$_cmdlet = "_Dummy"
						}

						if ( ((gi "Function:$_cmdlet").Definition -replace '\n').Split("{")[0] -match 'param\((.*\))\s*[;\.&a-zA-Z]*\s*$' )
						{
							$Matches[1].Split(',', "RemoveEmptyEntries" -as [System.StringSplitOptions]) -like "*$_param" |
							% { $_.Split("$ )`r`n", "RemoveEmptyEntries" -as [System.StringSplitOptions])[0] -replace '^\[(.*)\]$','$1' -as "System.Type" } |
							? { $_.IsEnum } | % { [Enum]::GetNames($_) -like $_opt | sort } | % { $_base + $_ }
						}
						break;
					}

					select -InputObject $_cmdlet -ExpandProperty ParameterSets | select -ExpandProperty Parameters |
					? { $_.Name -like $_param } | ? { $_.ParameterType.IsEnum } |
					% { [Enum]::GetNames($_.ParameterType) } | ? { $_ -like $_opt } | sort -Unique | % { $_base + $_ }

				}


				if ( $line[-1] -match "\s" ) { break; }

				if ( $lastWord -ne $null -and $lastWord.IndexOfAny('/\') -eq -1 ) {
					$command = $lastWord.Substring( ($lastWord -replace '([^\|\(;={]*)$').Length )
					$_base = $lastWord.Substring( 0, ($lastWord -replace '([^\|\(;={]*)$').Length )
					$pattern = $command + "*"
					"begin {", "break", "catch {", "continue", "data {", "do {", "else {", "elseif (",
					"end {", "exit", "filter ", "for (", "foreach ", "from", "function ", "if (", "in",
					"param (", "process {", "return", "switch ", "throw ", "trap ", "until (", "while (" `
					-like $pattern | % { $_base + $_ }
					gcm -Name $pattern -CommandType All | % { $_base + $_.Name } | sort -Unique
				}
			}
		}
	}

}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSJNkIn8OFs9lYu3r3XbjHn4A
# kdugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCp7pyQ79AAfo0DM
# EohLosOvDvQIMA0GCSqGSIb3DQEBAQUABIIBAAXXlKZ37Du9f6E/SXuDUw+vs66d
# /+1ncIf/i6BaODHyOAfTCD5lI+5SNQn02LLB7/ZFKr6VJb1aVgg65z7AKiDctpEL
# hYLosmCC4C5LeU5acBmOnBWf4uRDeaI5FEto9rbuyRVVbV20sOiYMzM/XlPfupJJ
# 9KooySXN0OeoMv+Gm7LVcdaBGrjSI0B0ObRScppufwjfMToIxj0RJEOhCGojft/v
# lKzee9UVhSxEGgg7q8sp7grqtUMNloyUx+kN0+MYFVz41ZCYqdyNtVG98d3ZHj1a
# tXF31pyPBr/jIUj9GAwWKpj8ImuSXTx9Pvaiws21AHMx5pt4NAZupu8Cqsw=
# SIG # End signature block
