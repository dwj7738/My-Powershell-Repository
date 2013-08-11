function Select-Scope {    
    <#
    .Synopsis
        Selects the current scope
    .Description
        Selects the current scope
    .Example
        Select-Scope
    #>
    
    
    
    $allTokens = @(Get-CurrentOpenedFileToken)
    $currentToken = Get-CurrentToken 
	
    $info = @{}
    for ($i = 0; $i -lt $allTokens.Count; $i++) {
		$token = $alltokens[$i]
		if ($token.StartLine -eq $currentToken.StartLine -and 
			$token.StartColumn -eq $currentToken.StartColumn) {
			$theSpot = $i
			# Having found this spot, go back until we find a groupstart or groupend, 
			# then go forward until we find the same
			
			$goingBack = $theSpot - 1
			$lastGroupStart = $null
            $relativeDepth = 0
			while ($goingBack -ge 0) {
                if ($allTokens[$goingBack].Type -eq 'GroupEnd') {
                    $relativeDepth++
                }
				if ($allTokens[$goingBack].Type -eq 'GroupStart') {
					if (-not $relativeDepth) { 
                        $lastGroupStart = $allTokens[$goingBack]
                        break
                    }
                    $relativeDepth--
				}
				$goingBack--
			}
            
			if (-not $lastGroupStart) { 
                $lastGroupStart = $allTokens[0] 
                $lastGroupStop = $allTokens[-1]
            } else {
                $goingForward =$goingBack + 1
                
    			$lastGroupEnd = $null            
                $relativeDepth = 1
    			while ($goingForward -lt $allTokens.Count) {
                    if ($allTokens[$goingForward].Type -eq 'GroupStart') {
                        $relativeDepth++
                    } 
    				if ($allTokens[$goingForward].Type -eq 'GroupEnd') {
                        $relativeDepth--					
    					if (-not $relativeDepth) {
                            $lastGroupEnd = $allTokens[$goingForward]
                            break
                        }
    				}
    				$goingForward++
    			}                
                if (-not $lastGroupEnd) { $lastGroupEnd = $allTokens[-1] } 
            }
            
            			
            if ($lastGroupStart -eq $allTokens[0] -and 
                $lastGroupEnd -eq $allTokens[-1]) {
                Select-TextInEditor -All
            } else {
    			$selectParams = @{
    				StartLine=$lastGroupStart.StartLine
    				StartColumn=$lastGroupStart.StartColumn
    				EndLine=$lastGroupEnd.EndLine
    				EndColumn=$lastGroupEnd.EndColumn
    			}
    			Select-TextInEditor @selectParams
            }
		}
	}
}

