

Function Get-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 ,  ValueFromPipeline = $true)]
      $VM = "%", 
      [String]$Name="%",
      
      [ValidateNotNullOrEmpty()]  
      $Server="." ,
      [Switch]$Current,  
      [Switch]$Newest, 
      [Switch]$Root
    )
    process{
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Get-VMSnapshot -VM $_  @PSBoundParameters}} 
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            if ($current)  {Get-wmiobject -computerName $vm.__server -Namespace $HyperVNamespace -q "associators of {$($vm.path)} where assocClass=MSvm_PreviousSettingData"}
            else {$Snaps=Get-WmiObject -computerName $vm.__server -NameSpace $HyperVNameSpace -Query "Select * From MsVM_VirtualSystemSettingData Where systemName='$($VM.name)' and instanceID <> 'Microsoft:$($VM.name)' and elementName like '$name' " 
                if   ($newest) {$Snaps | sort-object -property creationTime | select-object -last 1 } 
                elseif ($root) {$snaps | where-object {$_.parent -eq $null} }
                else           {$snaps}
            }
        }
    }
}



Function Get-VMSnapshotTree
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
      $VM, 
 
      [ValidateNotNullOrEmpty()] 
      $Server="."   #May need to look for VM(s) on Multiple servers
    )

    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
        $snapshots=(Get-VMSnapshot -VM $VM ) 
       if ($snapshots -is [array]) {out-tree -items $snapshots -startAt ($snapshots | where-object {$_.parent -eq $null}) -path "__Path" -Parent "Parent" -label "elementname"}
       else {$snapshots | foreach-object {"-" + $_.elementName} }
    }
}


Function New-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param( 
           [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
           $VM , 
           [string]$Note, 

           [ValidateNotNullOrEmpty()] 
           $Server=".", 
           
           [switch]$Wait,
           $PSC,
           [Switch]$Force)
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { New-VMsnapshot -VM $_  @PSBoundParameters}} 
        if (($vm.__CLASS -eq 'Msvm_ComputerSystem') -and ($force -or $psc.shouldProcess($VM.elementName , $lstr_NewSnapShot))) {
            $VSMgtSvc=Get-WmiObject -ComputerName $VM.__server -NameSpace  $HypervNameSpace -Class "MsVM_virtualSystemManagementService"
            $WMIResult = $VSMgtSvc.CreateVirtualSystemSnapshot($vm) 
            if ((Test-wmiResult -result $WMIResult -wait:$wait -JobWaitText ($lstr_NewSnapShot + $VM.elementName)`
                                -SuccessText ($lstr_NewSnapShotSuccess -f $VM.elementName) `
                                -failText    ($lstr_NewSnapShotFailure -f $VM.elementName)) -eq [ReturnCode]::OK) {
                $Snap = ([wmi]$WMIResult.Job).getRelated("Msvm_VirtualSystemSettingData")
                if ($note) {$Snap | foreach-object {set-vm -VM $_ -note $note -psc $psc -Force:$true  ; $_.get() ; $_ }}
                else       {$Snap | foreach-object {$_} } 
            }
        }
    }   
} 


Function Remove-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
        [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)][allowNull()]
        $Snapshot , 
        [Switch]$Tree , 
        [Switch]$wait,
        $PSC,
        [switch]$Force
        )
    Process {    
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ( $SnapShot.count -gt 1 ) {[Void]$PSBoundParameters.Remove("SnapShot") ;  $SnapShot | ForEach-object {Remove-VMSnapshot -snapshot $_  @PSBoundParameters}} 
        if (($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') -and ($force -or $psc.shouldProcess($snapshot.elementName , $lstr_RemoveSnapShot))) {
            $VSMgtSvc=Get-WmiObject -ComputerName $snapshot.__server -NameSpace  $HyperVNamespace -Class "MsVM_virtualSystemManagementService"
            if ($tree) {$result=$VSMgtSvc.RemoveVirtualSystemSnapshotTree($snapshot) }
            else       {$result=$VSMgtSvc.RemoveVirtualSystemSnapshot($snapshot)     }
            $result    | Test-wmiResult -wait:$wait -JobWaitText ($lstr_RemoveSnapShot + $snapshot.elementName)`
                                        -SuccessText ($lstr_RemoveSnapShotSuccess -f $snapshot.elementName) `
                                        -failText    ($lstr_RemoveSnapShotFailure -f $snapshot.elementName)  
       }
   }
}                


Function Rename-VMSnapshot 
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High' )]
    param (
        [parameter(ParameterSetName="Path" ,Mandatory = $true)]
        $VM, 
        [parameter(ParameterSetName="Path" , Mandatory = $true)][ValidateNotNullOrEmpty()][Alias("SnapshotName")]
        [String]$SnapName, 
        [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] 
        [string]$NewName, 
        [parameter(ParameterSetName="Path")][ValidateNotNullOrEmpty()] 
        $Server=".",   #May need to look for VM(s) on Multiple servers
        [parameter(ParameterSetName="Snap" , Mandatory = $true, ValueFromPipeline = $true)]
        $Snapshot,
        $PSC,
        [switch]$Force 
    )    
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 )  {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Rename-VMsnapshot -VM $_  @PSBoundParameters}} 
        if (($pscmdlet.ParameterSetName -eq "Path") -and ($vm.__CLASS -eq 'Msvm_ComputerSystem')) { $snapshot=Get-VmSnapshot -vm $vm -name $snapName }
        if ($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') {Set-vm -VM $snapshot -Name $newName -psc $psc -force:$force }
    }     
}


Function Restore-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)]
      $SnapShot, 
      
      $PSC, 
 
      [Switch]$Force , 
      [Switch]$Restart, 
      [Switch]$wait)
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
         if ($SnapShot.count -gt 1 ) {[Void]$PSBoundParameters.Remove("SnapShot") ;  $SnapShot | ForEach-object {Restore-snapshot -snapshot $_  @PSBoundParameters}} 
         if ($snapshot.__class -eq 'Msvm_VirtualSystemSettingData') {
             $VM = Get-WmiObject -computername $snapshot.__server -NameSpace "root\virtualization" -Query ("Select * From MsVM_ComputerSystem Where Name='$($Snapshot.systemName)' " )
             if ($vm.enabledState -ne [vmstate]::stopped) {write-warning ($lstr_VMWillBeStopped -f $vm.elementname , [vmstate]$vm.enabledState) ; Stop-VM $vm -wait -psc $psc -force:$force}
             if ($force -or $psc.shouldProcess($vm.ElementName , $Lstr_RestoreSnapShot)) {
                 $VSMgtSvc=Get-WmiObject -ComputerName $snapshot.__server -NameSpace  "root\virtualization" -Class "MsVM_virtualSystemManagementService" 
                 if ( ($VSMgtSvc.ApplyVirtualSystemSnapshot($VM,$snapshot)  | Test-wmiResult -wait:$wait -JobWaitText ($lstr_RestoreSnapShot + $vm.elementName)`
                                                                            -SuccessText ($lstr_RestoreSnapShotSuccess -f $VM.elementname) `
                                                                            -failText ($lstr_RestoreSnapShotFailure -f  $vm.elementname) ) -eq [returnCode]::ok) {if ($Restart) {Start-vm $vm}  }
              }
         }
    } 
}



Function Select-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    Param(
      [parameter(Position=0 , Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()] 
      $VM, 
 
      [ValidateNotNullOrEmpty()] 
      $Server="."   #May need to look for VM(s) on Multiple servers
    )
    if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
    if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
 	    $snapshots=(Get-VMSnapshot -vm $VM)
	    if ($snapshots -is [array]) {Select-Tree -items $snapshots -startAt ($snapshots | where-object {$_.parent -eq $null}) -path "__Path" -Parent "Parent" -label "elementname"}
         else                       {$snapshots}
    }
            
}


Function Update-VMSnapshot
{# .ExternalHelp  MAML-VMSnapshot.XML
    [CmdletBinding(SupportsShouldProcess=$true  , ConfirmImpact='High' )]
    Param(
        [parameter( Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()] 
        $VM , 
        
        [Alias("SnapshotName")]
        $SnapName, 
        
        $Note,
        
        [ValidateNotNullOrEmpty()] 
        $Server=".",
        $PSC,
        [Switch]$Force
        ) 
    process {
        if ($psc -eq $null)  {$psc = $pscmdlet} ; if (-not $PSBoundParameters.psc) {$PSBoundParameters.add("psc",$psc)}
        if ($VM -is [String]) {$VM=(Get-VM -Name $VM -Server $server) }
        if ($VM.count -gt 1 ) {[Void]$PSBoundParameters.Remove("VM") ;  $VM | ForEach-object { Update-VMSnapshot -VM $_  @PSBoundParameters}} 
        if ($vm.__CLASS -eq 'Msvm_ComputerSystem') {
            if ($snapName -eq $null) {$snapName=(Get-VMSnapshot $vm -newest ).elementname } 
            If ($snapName) {rename-VMsnapshot  -vm $vm -SnapName $snapName -newName "Delete-me" -force:$force -psc $psc}
            new-vmSnapshot $vm -wait -note $note -force:$force -psc $psc | rename-VMsnapshot -Newname $snapName -force:$force -psc $psc
            Get-VmSnapShot $vm -name "Delete-me" | remove-vmSnapShot -wait -force:$force -psc $psc -ErrorAction silentlycontinue
        }
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVX2HfZLc5B0/b8FCKYhaEENA
# sTegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAby5NqpvXc+vVTJ
# W3lcp5kamazaMA0GCSqGSIb3DQEBAQUABIIBALfRnEMU3zwRhIDORQiYlRJwzZ11
# SG5/tbcDGVX0pTxL2UDY6O09foXPnux3fEJ65xCno0UY/QgoJXcVQo3GDVjnIDJG
# tqC+F72ws+c3Vj8djNML8kZwowjfKMENNtC8iVz0WBjGETVA61hej90AyXkr/FzR
# Ofj5BvWuZN0ZPoC9IwJKU7OaL/aeU+M1s9NqtXFuZb9yAoWyTQfdNghLHN8P2Rcj
# sZ8KD6SkjXixcJDuseOPYzu2s/nSp1+eaEGQETB0vhZZ5b5wVHgLTXYy8Sz8t/IV
# UgMXaV/kHty8Cxf1PIIdwqqL09Wsdl5VKYd5cxwfQQctmfDnJJ1NVna+pao=
# SIG # End signature block
