#.Synopsis
#  Creates a fir tree in your console!
#.Description
#  A simple christmas tree simulation with (optional) flashing lights. 
#  Requires your font be set to a True Type font (best results with Consolas).
#.Parameter Trim
#  Whether or not to trim the tree. NOTE: In violation of convention, this switch to true!
#  To disable the tree lights, use Get-Tree -Trim:$false 
#.Example
#  Get-Tree -Trim:$false 
#.Example
#  Get-tree Red, Cyan, Blue, Gray, Green
#
#  Description
#  -----------
#  Creates a tree with multi-colored lights in the five colors that work best...
param(
   [switch]$Trim=$true
, 
   [ValidateSet("Red","Blue","Cyan","Yellow","Green","Gray","Magenta","All")]
   [Parameter(Position=0)]
   [String[]]$LightColor = @("Red")
)
if($LightColor -contains "All") {
   $LightColor = "Red","Yellow","Green","Gray","Magenta","Cyan","Blue"
}

Clear-Host
$OFS = "`n"
$center = [Math]::Min( $Host.UI.RawUI.WindowSize.Width, $Host.UI.RawUI.WindowSize.Height ) - 10

$Sparkle = [string][char]0x0489  
$DkShade = [string][char]0x2593
$Needles  = [string][char]0x0416

$Width = 2
[string[]]$Tree = $(
   "$(" " * $Center) "
   "$(" " * $Center)$([char]0x039B)"
   "$(" " * ($Center - 1))$($Needles * 3)"
  
   for($i = 3; $i -lt $center; $i++) {
      (" " * ($Center - $i)) + (Get-Random $Needles, " ") + ($Needles * (($Width * 2) + 1)) + (Get-Random $Needles, " ")
      $Width++
   }
   for($i = 0; $i -lt 4; $i++) {
      " " * ($Center + 2)
   }
) 

$TreeOn = $Host.UI.RawUI.NewBufferCellArray( $Tree, "DarkGreen", "DarkMagenta" )
$TreeOff = $Host.UI.RawUI.NewBufferCellArray( $Tree, "DarkGreen", "DarkMagenta" )

# Make the tree trunk black
for($x=-2;$x -le 2;$x++) { 
   for($y=0;$y -lt 4;$y++) {
      $TreeOn[($center+$y),($center+$x)] = $TreeOff[($center+$y),($center+$x)] = 
         New-Object System.Management.Automation.Host.BufferCell $DkShade, "Black", "darkMagenta", "Complete"
   }  
}

if($trim) {
$ChanceOfLight = 50
$LightIndex = 0
for($y=0;$y -le $TreeOn.GetUpperBound(0);$y++) {
   for($x=0;$x -le $TreeOn.GetUpperBound(1);$x++) {
      # only put lights on the tree ...
      if($TreeOn[$y,$x].Character -eq $Needles) {
         $LightIndex += 1
         if($LightIndex -ge $LightColor.Count) {
            $LightIndex = 0
         }
         # distribute the lights randomly, but not next to each other
         if($ChanceOfLight -gt (Get-Random -Max 100)) {
            # Red for on and DarkRed for off.
            $Light = $LightColor[$LightIndex]
            $TreeOn[$y,$x] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, $Light, "darkMagenta", "Complete"
            $TreeOff[$y,$x] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, "Dark$Light", "darkMagenta", "Complete"
            $ChanceOfLight = 0 # Make sure the next spot won't have a light
         } else { 
            # Increase the chance of a light every time we don't have one
            $ChanceOfLight += 3
         }
      }
   }
}
# Set the star on top
$TreeOn[0,$Center] = $TreeOff[0,$Center] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, "Yellow", "darkMagenta", "Complete"
}


# Figure out where to put the tree
$Coord = New-Object System.Management.Automation.Host.Coordinates (($Host.UI.RawUI.WindowSize.Width - ($Center*2))/2), 2
$Host.UI.RawUI.SetBufferContents( $Coord, $TreeOff )

while($trim) { # flash the lights on and off once per second, if we trimmed the tree
   sleep -milli 500
   $Host.UI.RawUI.SetBufferContents( $Coord, $TreeOn )
   sleep -milli 500
   $Host.UI.RawUI.SetBufferContents( $Coord, $TreeOff )
}