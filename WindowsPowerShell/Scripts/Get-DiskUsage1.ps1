    Function Get-DiskUsage {
     
    <#
     
    .SYNOPSIS
    A tribute to the excellent Unix command DU.
     
    .DESCRIPTION
    This command will output the full path and the size of any object
    and it's subobjects. Using just the Get-DiskUsage command without
    any parameters will result in an output of the directory you are
    currently placed in and it's subfolders.
     
    .PARAMETER Path
    If desired a path can be specified with the Path parameter. In no path
    is specified $PWD will be used.
     
    .PARAMETER h
    the -h paramater is the same as -h in Unix. It will list the folders
    and subfolders in the most appropriate unit depending on the size
    (i.e. Human Readable).
     
    .PARAMETER l
    The -l paramater will add the largest file to the end of the output.
     
    .PARAMETER Sort
    Allows you to sort by Folder or Size. If none i specified the default
    of Folder will be used.
     
    .PARAMETER Depth
    Depth will allow you to specify a maximum recursion depth. A depth
    of 1 would return the immediate subfolders under the root.
     
    .PARAMETER Force
    Works the same way as Get-ChildItem -force.
     
    .PARAMETER Descending
    Works the same way as Sort-Object -descending.
     
    .LINK
    http://www.donthaveasite.nu
     
    .NOTES
    Author: Jonas Hallqvist
    Developed with Powershell v3
     
    #>
     
        [CmdletBinding(
            SupportsShouldProcess=$True
        )]
     
        param (
            [String]$Path=$PWD,
            [Switch]$h,
            [Switch]$l,
            [String]$Sort="Folder",
            [Int]$Depth,
            [Switch]$Force,
            [Switch]$Descending
        )
     
        $ErrorActionPreference = "silentlycontinue"
     
        function HumanReadable {
            param ($size)
            switch ($size) {
                {$_ -ge 1PB}{"{0:#'P'}" -f ($size / 1PB); break}
                {$_ -ge 1TB}{"{0:#'T'}" -f ($size / 1TB); break}
                {$_ -ge 1GB}{"{0:#'G'}" -f ($size / 1GB); break}
                {$_ -ge 1MB}{"{0:#'M'}" -f ($size / 1MB); break}
                {$_ -ge 1KB}{"{0:#'K'}" -f ($size / 1KB); break}
                default {"{0}" -f ($size) + "B"}
            }
        }
     
        function LargestFolder {
            if ($h) {
                $large = ($results | Sort-Object -Property Size -Descending)[0] | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder  -AutoSize -HideTableHeaders
                Write-host "Largest Folder is:" -NoNewline
                $large
            }
            else {
                $large = ($results | Sort-Object -Property Size -Descending)[0] | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize -HideTableHeaders
                Write-host "Largest Folder is:" -NoNewline
                $large
            }
        }
     
        function Max-Depth {
            param(
                [String]$Path = '.',
                [String]$Filter = '*',
                [Int]$Level = 0,
                [Switch]$Force,
                [Switch]$Descending,
                [int]$i=0
            )
            $results=@()
            $root = (Resolve-Path $Path).Path
     
            if ($root -notmatch '\\$') {$root += '\'}
     
            if (Test-Path $root -PathType Container) {
     
                do {
                    [String[]]$_path += $root + "$Filter"
                    $Filter = '*\' + $Filter
                    $i++
                }
                until ($i -eq $Level)
     
                $dirs=Get-ChildItem -directory $_path -Force:$Force
       
                foreach ($dir in $dirs) {
                    $size = 0
                    $size += (gci $dir.Fullname -recurse | Measure-Object -Property Length -Sum).Sum
                    $results += New-Object psobject -Property @{Folder=$dir.fullname;Size=$size}
                }
                if ($h) {
                    $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder -AutoSize
                }
                if ($l) {
                    LargestFolder
                }
                if (($h -eq $false) -and ($l -eq $false)) {
                    $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize
                }
            }
        }
     
        if ($Depth) {
            Max-Depth -Path $Path -Level $Depth -Force:$Force -Descending:$Descending
        }
     
        else {
            $results = @()
            $dirs=Get-ChildItem -directory $Path -Force:$Force -Recurse
            foreach ($dir in $dirs) {
                $size = 0
                $size += (gci $dir.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
                $results+= New-Object psobject -Property @{Folder=$dir.FullName;Size=$size}
            }
            if ($h) {
                $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder -AutoSize
            }
            if ($l) {
                LargestFolder
            }
            if (($h -eq $false) -and ($l -eq $false)) {
                $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize
            }
        }
    }
     
    <#
    Copyright (c) 2013, Jonas Hallqvist
     All rights reserved.
     
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
     
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
    THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    #>
