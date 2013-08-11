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