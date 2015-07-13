#TheGameOfLife.ps1

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$SCRIPT:hostProperties = @{};
$SCRIPT:hostState = $null;
$SCRIPT:BoardWidth = 50;
$SCRIPT:BoardHeight = 50;

Function Initialize-Host
{
	Param(
		[Parameter(Mandatory=$false)]
		$wndTitle = "Game of Life...",
		[Parameter(Mandatory=$false)]
		[Int]$wndWidth=50,
		[Parameter(Mandatory=$false)]
		[Int]$wndHeight=50
	)
	$wndSize = $Host.UI.RawUI.WindowSize;
	$wndSize.Width = $wndWidth;
	$wndSize.Height = $wndHeight;
	
	$wndBuffSize = $wndSize;
	
	#Set Console
	$Host.UI.RawUI.WindowTitle = $wndTitle;
	$Host.UI.RawUI.WindowSize  = $wndSize;
	$Host.UI.RawUI.BufferSize  = $wndBuffSize;
	$Host.UI.RawUI.CursorSize  = 0;
	$Host.UI.RawUI.ForegroundColor = "Green";
	$Host.UI.RawUI.BackgroundColor = "Black";

	#get a clear the screen.
	Clear-Host;
}

Function Push-Host
{
	#Get the full buffer
	$hostRect       = "System.Management.Automation.Host.Rectangle"
	$bufferObject   = New-Object $hostRect 0, 0, $(($Host.UI.RawUI.BufferSize).Width), $(($Host.UI.RawUI.BufferSize).Height)
	
	$SCRIPT:hostProperties= @{
    	"Title"           = $Host.UI.RawUI.WindowTitle
		"WindowSize"      = $Host.UI.RawUI.WindowSize
    	"WindowPosition"  = $Host.UI.RawUI.WindowPosition 
    	"BufferSize"      = $Host.UI.RawUI.BufferSize    
    	"Buffer"          = $Host.UI.RawUI.GetBufferContents($bufferObject)    
    	"Background"      = $Host.UI.RawUI.BackgroundColor    
    	"Foreground"      = $Host.UI.RawUI.ForegroundColor
    	"CursorSize"      = $Host.UI.RawUI.CursorSize
    	"CursorPosition"  = $Host.UI.RawUI.CursorPosition
	}
	
	$SCRIPT:hostState = New-Object -TypeName PSCustomObject -Property $SCRIPT:hostProperties
}

Function Pop-Host
{
	#Restore buffer contents
	$Host.UI.RawUI.BufferSize     = $SCRIPT:hostState.BufferSize;
	$initPosition = $Host.UI.RawUI.WindowPosition;
	$initPosition.x = 0;
	$initPosition.y = 0;
	$Host.UI.RawUI.SetBufferContents($initPosition, $SCRIPT:hostState.Buffer)
	
	#Start with the window
	$Host.UI.RawUI.WindowTitle    = $SCRIPT:hostState.Title;
	$Host.UI.RawUI.WindowPosition = $SCRIPT:hostState.WindowPosition;
	$Host.UI.RawUI.WindowSize     = $SCRIPT:hostState.WindowSize;
		
	#Set cursor
	$Host.UI.RawUI.CursorSize     = $SCRIPT:hostState.CursorSize;
	$Host.UI.RawUI.CursorPosition = $SCRIPT:hostState.CursorPosition;
	
	#set colors
	$Host.UI.RawUI.ForegroundColor = $SCRIPT:hostState.Foreground;
	$Host.UI.RawUI.BackgroundColor = $SCRIPT:hostState.Background;
}

Function Get-CursorPosition
{
	$dY = ([System.Windows.Forms.Cursor]::Position.Y )  #read the Y coordinates
  	$dX = ([System.Windows.Forms.Cursor]::Position.X )  #read the X coordinates
	return @($dX, $dY)
}

Function Draw-Pixel
{
	param(
		[Parameter(Mandatory=$true)]
		[Int]$X,
		[Parameter(Mandatory=$true)]
		[Int]$Y,
		[Parameter(Mandatory=$false)]
		[String]$ForeColor = 'White',
		[Parameter(Mandatory=$false)]
		[String]$BackColor = 'Black',
		[Parameter(Mandatory=$false)]
		[String]$pixel = [Char]9608
	)
	$pos = $Host.UI.RawUI.WindowPosition
	$pos.x = $x
	$pos.y = $y
	$row = $Host.UI.RawUI.NewBufferCellArray($pixel, $ForeColor, $BackColor) 
	$Host.UI.RawUI.SetBufferContents($pos,$row) 
}

#Initialize a full board of dead cells.
Function Initialize-GameMatrix
{
    param(
    [Int32]$M,
    [Int32]$N
    )
    $gameMatrix = New-Object "Int32[,]" $M, $N
    for($i=0; $i -lt $M; $i++)
    {
        for($j=0; $j -lt $N; $j++)
        {
            $gameMatrix[$i, $j] = 0;
        }
    }
    return ,$gameMatrix
}

#show the game board in 1's and 0's
Function Show-Matrix
{
	param(
		[Int[,]]$matrix
	)
	[Int]$m = $matrix.GetLength(0);
	[Int]$n = $matrix.GetLength(1);
	
    for($i=0; $i -lt $m; $i++)
	{
		for($j=0; $j -lt $n; $j++)
	    {
			Write-Host("{0}" -f $matrix[$i,$j]) -NoNewLine;
	    }
		Write-Host ""
	}
}

#Currently Taking 10.5 Secs to generate next generation.
#consumes around 20-25% cpu.
#need to find a better way to do this.
Function Get-NextGeneration
{
	param(
	 [Int[,]]$GameMatrix
	)
	BEGIN
	{
		$tmpGameMatrix = $GameMatrix;
		#The game board for game of life is infinite. So, we simulate this by wrapping the
		#width and height.
		Function Get-WrappedWidth
		{
			param(
			    [Int]$x,
			    [Int]$xEdge
			)
			$x += $xEdge;
			if($x -lt 0){
				$x += $SCRIPT:BoardWidth;
			}elseif($x -ge $SCRIPT:BoardWidth){
				$x -= $SCRIPT:BoardWidth;
			}
			return $x;
		}

		Function Get-WrappedHeight
		{
			param(
				[Int]$y,
				[Int]$yEdge
			)
			$y += $yEdge;
			if($y -lt 0){
				$y += $SCRIPT:BoardHeight;
			}elseif($y -ge $SCRIPT:BoardHeight){
				$y -= $SCRIPT:BoardHeight
			}
			return $y;
		}

		Function Get-Neighbours
		{
			param(
				[Int[,]]$ArrayMatrix,
				[Int]$coordX,
				[Int]$coordY
			)
			[Int]$nx = 0;
			[Int]$ny = 0;
			[Int]$count = 0;
			for($nx = -1; $nx -le 1; $nx++)
			{
				for($ny = -1; $ny -le 1; $ny++)
				{
					if($nx -or $ny)
					{
						if($ArrayMatrix[$(Get-WrappedWidth $coordX $nx), $(Get-WrappedHeight $coordY $ny)])
						{
							$count += 1;
						}
					}
				}
			}
			return $count;
		}
		
	}
	PROCESS
	{
		
		for($x = 0; $x -lt $SCRIPT:BoardWidth; $x++)
		{
			for($y = 0; $y -lt $SCRIPT:BoardHeight; $y++)
			{
				$neighbors = Get-Neighbours $tmpGameMatrix $x $y
				switch($neighbors)
				{
					{($neighbors -lt 2) -or ($neighbors -gt 3)}{$tmpGameMatrix[$x, $y] = 0;}
					{($neighbors -eq 3)}{$tmpGameMatrix[$x, $y] = 1;}
				}
			}
		}
		
	}
	END
	{
		$GameMatrix = $tmpGameMatrix;
		#should we even do this? : return ,$GameMatrix
		return ,$GameMatrix;
	}
}

Function Draw-Board
{
	param(
		[Int[,]]$Board
	)
	for($bx = 0; $bx -lt $SCRIPT:BoardWidth; $bx++)
	{
		for($by = 0; $by -lt $SCRIPT:BoardHeight; $by++)
		{
			if($Board[$bx, $by])
			{
				Draw-Pixel -X $bx -Y $by -ForeColor "Green" -BackColor "Yellow"
			}else{
				Draw-Pixel -X $bx -Y $by -ForeColor "Black" -BackColor "Black"
			}
		}
	}
}

#Setting a little bit of complex pattern on the board.
Function Set-SampleOnBoard
{
	param(
		[Int[,]]$ArrayMatrix
	)
	$ArrayMatrix[6,1] = 1
	$ArrayMatrix[7,1] = 1
	$ArrayMatrix[6,2] = 1
	$ArrayMatrix[7,2] = 1
	$ArrayMatrix[6,11] = 1
	$ArrayMatrix[7,11] = 1
	$ArrayMatrix[8,11] = 1
	$ArrayMatrix[9,12] = 1
	$ArrayMatrix[10,13] = 1
	$ArrayMatrix[10,14] = 1
	$ArrayMatrix[9,16] = 1
	$ArrayMatrix[8,17] = 1
	$ArrayMatrix[7,17] = 1
	$ArrayMatrix[6,17] = 1
	$ArrayMatrix[5,16] = 1
	$ArrayMatrix[4,14] = 1
	$ArrayMatrix[4,13] = 1
	$ArrayMatrix[5,12] = 1
	$ArrayMatrix[7,15] = 1
	$ArrayMatrix[7,18] = 1
	$ArrayMatrix[4,21] = 1
	$ArrayMatrix[5,21] = 1
	$ArrayMatrix[6,21] = 1
	$ArrayMatrix[4,22] = 1
	$ArrayMatrix[5,22] = 1
	$ArrayMatrix[6,22] = 1
	$ArrayMatrix[7,23] = 1
	$ArrayMatrix[3,23] = 1
	$ArrayMatrix[3,25] = 1
	$ArrayMatrix[2,25] = 1
	$ArrayMatrix[7,25] = 1
	$ArrayMatrix[8,25] = 1
	$ArrayMatrix[3,35] = 1
	$ArrayMatrix[3,36] = 1
	$ArrayMatrix[4,35] = 1
	$ArrayMatrix[4,36] = 1
	return ,$ArrayMatrix;
}
Function Main
{
	Push-Host;
	Initialize-Host;
	$gameBoard = Initialize-GameMatrix 50 50;
	#Sample filler
	$gameBoard = Set-SampleOnBoard $gameBoard
	Draw-Board $gameBoard
	do{
		$newBoard = Get-NextGeneration $gameBoard;
		#Clear-Host;
		Draw-Board $newBoard;
	}until($Host.UI.RawUI.KeyAvailable)
	Pop-Host;
}
. Main
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFQZzTLvX+l60Xc/iHzeXIONI
# zDmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCqc2l9D94Y8heNh
# kEZNO0c1JlO0MA0GCSqGSIb3DQEBAQUABIIBAK2ikPEZIMyjjEWFSN+dRMEj1Kjc
# 1C6od+nZFGV8e1a3ZjkdJutteOcK2Y/tZZoZ/imdHdixlkp3yLXOtKaFk1snDMkK
# DjtBi3zUt8FBEl5z8fDi+JiI+cMHFoAgKoX9ma0RQsafl8csOI8MatLECYJIBnWQ
# t3/E4yKEx9p5H4nVF8sqvO7oxltOLAaA9LjonZPrEPW4PW6Mja0I2FbcuWPFE1jA
# KKPQy+QOG16z43Z3gP1QOdJ0gLjMfBfwAZVd4JWt42fQ9SCp1eDpzAr8xjg/F3bz
# bPzTq07n4e+ZPq3pFAYc6LRQPa6tuVxwjAm3mVUKeA86/Zq5xYmWIgcn0zg=
# SIG # End signature block
