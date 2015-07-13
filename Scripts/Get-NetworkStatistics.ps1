function Get-NetworkStatistics
{
	[OutputType('System.Management.Automation.PSObject')]
	[CmdletBinding(DefaultParameterSetName='name')]
	
	param(
		[Parameter(Position=0,ValueFromPipeline=$true,ParameterSetName='port')]
		[System.Int32]$Port='*',
		
		[Parameter(Position=0,ValueFromPipeline=$true,ParameterSetName='name')]
		[System.String]$ProcessName='*',
		
		[Parameter(Position=0,ValueFromPipeline=$true,ParameterSetName='address')]
		[System.String]$Address='*',		
		
		[Parameter()]
		[ValidateSet('*','tcp','udp')]
		[System.String]$Protocol='*',

		[Parameter()]
		[ValidateSet('*','Closed','CloseWait','Closing','DeleteTcb','Established','FinWait1','FinWait2','LastAck','Listen','SynReceived','SynSent','TimeWait','Unknown')]
		[System.String]$State='*'
		
	)
    
	begin
	{
		$properties = 'Protocol','LocalAddress','LocalPort'
    		$properties += 'RemoteAddress','RemotePort','State','ProcessName','PID'
	}
	
	process
	{
	    netstat -ano | Select-String -Pattern '\s+(TCP|UDP)' | ForEach-Object {

	        $item = $_.line.split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)

	        if($item[1] -notmatch '^\[::')
	        {           
	            if (($la = $item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6')
	            {
	               $localAddress = $la.IPAddressToString
	               $localPort = $item[1].split('\]:')[-1]
	            }
	            else
	            {
	                $localAddress = $item[1].split(':')[0]
	                $localPort = $item[1].split(':')[-1]
	            } 

	            if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6')
	            {
	               $remoteAddress = $ra.IPAddressToString
	               $remotePort = $item[2].split('\]:')[-1]
	            }
	            else
	            {
	               $remoteAddress = $item[2].split(':')[0]
	               $remotePort = $item[2].split(':')[-1]
	            } 
				
				$procId = $item[-1]
				$procName = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name
				$proto = $item[0]
				$status = if($item[0] -eq 'tcp') {$item[3]} else {$null}				
				
				
				$pso = New-Object -TypeName PSObject -Property @{
					PID = $procId
					ProcessName = $procName
					Protocol = $proto
					LocalAddress = $localAddress
					LocalPort = $localPort
					RemoteAddress =$remoteAddress
					RemotePort = $remotePort
					State = $status
				} | Select-Object -Property $properties								


				if($PSCmdlet.ParameterSetName -eq 'port')
				{
					if($pso.RemotePort -like $Port -or $pso.LocalPort -like $Port)
					{
					    if($pso.Protocol -like $Protocol -and $pso.State -like $State)
						{
							$pso
						}
					}
				}

				if($PSCmdlet.ParameterSetName -eq 'address')
				{
					if($pso.RemoteAddress -like $Address -or $pso.LocalAddress -like $Address)
					{
					    if($pso.Protocol -like $Protocol -and $pso.State -like $State)
						{
							$pso
						}
					}
				}
				
				if($PSCmdlet.ParameterSetName -eq 'name')
				{		
					if($pso.ProcessName -like $ProcessName)
					{
						if($pso.Protocol -like $Protocol -and $pso.State -like $State)
						{
					   		$pso
						}
					}
				}
	        }
	    }
	}
<#

.SYNOPSIS
	Displays the current TCP/IP connections.

.DESCRIPTION
	Displays active TCP connections and includes the process ID (PID) and Name for each connection.
	If the port is not yet established, the port number is shown as an asterisk (*).	
	
.PARAMETER ProcessName
	Gets connections by the name of the process. The default value is '*'.
	
.PARAMETER Port
	The port number of the local computer or remote computer. The default value is '*'.

.PARAMETER Address
	Gets connections by the IP address of the connection, local or remote. Wildcard is supported. The default value is '*'.

.PARAMETER Protocol
	The name of the protocol (TCP or UDP). The default value is '*' (all)
	
.PARAMETER State
	Indicates the state of a TCP connection. The possible states are as follows:
		
	Closed	 	- The TCP connection is closed. 
	CloseWait 	- The local endpoint of the TCP connection is waiting for a connection termination request from the local user. 
	Closing 	- The local endpoint of the TCP connection is waiting for an acknowledgement of the connection termination request sent previously. 
	DeleteTcb 	- The transmission control buffer (TCB) for the TCP connection is being deleted. 
	Established 	- The TCP handshake is complete. The connection has been established and data can be sent. 
	FinWait1 	- The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint or for an acknowledgement of the connection termination request sent previously. 
	FinWait2 	- The local endpoint of the TCP connection is waiting for a connection termination request from the remote endpoint. 
	LastAck 	- The local endpoint of the TCP connection is waiting for the final acknowledgement of the connection termination request sent previously. 
	Listen	 	- The local endpoint of the TCP connection is listening for a connection request from any remote endpoint. 
	SynReceived 	- The local endpoint of the TCP connection has sent and received a connection request and is waiting for an acknowledgment. 
	SynSent 	- The local endpoint of the TCP connection has sent the remote endpoint a segment header with the synchronize (SYN) control bit set and is waiting for a matching connection request. 
	TimeWait	- The local endpoint of the TCP connection is waiting for enough time to pass to ensure that the remote endpoint received the acknowledgement of its connection termination request. 
	Unknown		- The TCP connection state is unknown.
	
	Values are based on the TcpState Enumeration:
	http://msdn.microsoft.com/en-us/library/system.net.networkinformation.tcpstate%28VS.85%29.aspx

.EXAMPLE
	Get-NetworkStatistics

.EXAMPLE
	Get-NetworkStatistics iexplore

.EXAMPLE
	Get-NetworkStatistics -ProcessName md* -Protocol tcp 

.EXAMPLE
	Get-NetworkStatistics -Address 192* -State LISTENING 

.EXAMPLE
	Get-NetworkStatistics -State LISTENING -Protocol tcp

.OUTPUTS
	System.Management.Automation.PSObject

.NOTES
	Author: Shay Levy
	Blog  : http://PowerShay.com
#>	
}

help Get-NetworkStatistics
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqQ0IHX0idfHE2dphSACEW6G8
# lzigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKAvMUGLW1olPsix
# rXCVlOHRHHhxMA0GCSqGSIb3DQEBAQUABIIBAA9xrUmBqZP8HqIF3rD97Uo8rf7X
# q0MYtce++OW1VwKvoMY+L+ypz44WZPzYge6UAKflIj5MtnC45YYhg60eDUxCTmCS
# tRGyFoSgfPgFIxbu091VXve+upNzM/+/y1PoA9v/+BmaZ38FOI5/TQR2QCfQzAHn
# H8YyBM0oDyn6NgTszntVgHB2eLyQe/snQEreCAqXOflvtNgGZ1v2mvGhyPt2LVJP
# c1+mAeBfLOQVsRHs3DZTz/96zJcUm1aMA9AJGyWe4wdchSyucH6PofaHm3cRF2Ej
# RjWPxilXfiHKMfyu5XvJPLAOzt+JzH6HQUpVzdAnEmLtWVaJVbLv6QpViT4=
# SIG # End signature block
