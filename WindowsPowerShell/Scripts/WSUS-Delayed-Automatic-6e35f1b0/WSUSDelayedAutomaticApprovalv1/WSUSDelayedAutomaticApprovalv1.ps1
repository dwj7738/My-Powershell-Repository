Param(
	[string]$WsusServer = (([system.net.dns]::GetHostByName('localhost')).hostname),
	[int]$PortNumber = 8530,
	[bool]$UseSSL = $False,
	[bool]$TrialRun = $False
)

[bool]$Debug = $False

#Connect to the WSUS 3.0 interface.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$UpdateServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UseSSL,$PortNumber);
If($? -eq $False) {
	$ErrorActionPreference = $script:CurrentErrorActionPreference
	Return
} Else {
	$UpdateServer
}

$InstallApprovalRules = $UpdateServer.GetInstallApprovalRules() | Where { $_.Name -like "Delayed*"} 
If($InstallApprovalRules) {
	$InstallApprovalRules | ForEach {
		[int]$Count = 0
		[bool]$Warning = $False
		$_
		[String]::Format("Name: {0}", $_.Name)
		If ($_.Enabled) {
			[String]::Format("Enabled: {0} WARNING", $_.Enabled)
			$Warning = $True
		} Else {
			[String]::Format("Enabled: {0}", $_.Enabled)
		}
		If ($_.Deadline) {
			[String]::Format("Deadline: {0} days and {1} Minutes after Midnight (UTC)", $_.Deadline.DayOffSet, $_.Deadline.MinutesAfterMidnight)
		} Else {
			[String]::Format("Deadline: {0}","No set")
		}

		If ([int]$_.Name.Split(" ")[1] -gt 0) {
			[String]::Format("Delayed: {0} days", [int]$_.Name.Split(" ")[1])
		} Else {
			[String]::Format("Delayed: Not set WARNING")
			$Warning = $True
		}

		[String]::Format("Categories: {0}", $_.GetCategories().Count)
		[String]::Format("Classifications: {0}", $_.GetUpdateClassifications().Count)
		[String]::Format("Computer target groups: {0}",$_.GetComputerTargetGroups().Count)
		If (!$Warning) {
			$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
			$UpdateApprovalScope = New-Object Microsoft.UpdateServices.Administration.UpdateApprovalScope

			$UpdateScope.Categories.AddRange($_.GetCategories())
			$UpdateScope.Classifications.AddRange($_.GetUpdateClassifications())
			$updateScope.toArrivalDate = [DateTime]::UtcNow.Adddays(-1 * [int]$_.Name.Split(" ")[1])

			$DelayedUpdates =  ($UpdateServer.GetUpdates($UpdateScope) | Where {!$_.IsDeclined})
			
			ForEach ($DelayedUpdate in $DelayedUpdates ) {
				[bool]$Approved = $False
				If ($Debug) {$DelayedUpdate.Title}
				If ($DelayedUpdate.isApproved) {
					ForEach ($GroupApproval in $DelayedUpdate.GetUpdateApprovals()) {
						ForEach ($TargetGroup in $_.GetComputerTargetGroups()) {
							If ($GroupApproval.ComputerTargetGroupId -eq $TargetGroup.Id) {
								$Approved = $True
								If ($Debug) {"Approved for " + $TargetGroup.Name}
								break
							}
						}
						If ($GroupApproval.ComputerTargetGroupId -eq [Microsoft.UpdateServices.Administration.ComputerTargetGroupId]::AllComputers) {
							$Approved = $True
							If ($Debug) {"Approved for " + $UpdateServer.GetComputerTargetGroup([Microsoft.UpdateServices.Administration.ComputerTargetGroupId]::AllComputers).Name}
							break
						}
						If ($Approved) { break }
					}
				}
				If (!$Approved) {
					$Count ++
					If ($Debug) {"Not Approved"}
					If (!$Trialrun) {
						If (!$Debug) {$DelayedUpdate.Title}
						ForEach ($ComputerGroup in $_.GetComputerTargetGroups()) {
							
							If ($_.Deadline) {
								[dateTime]$Deadline = [datetime]::UtcNow.Date.Adddays($_.Deadline.DayOffSet).AddMinutes($_.Deadline.MinutesAfterMidnight)
								If ($DelayedUpdate.Approve("Install", $ComputerGroup, $Deadline)) {
									[String]::Format("Approved for targetgroup {0} with deadline {1}", $ComputerGroup.Name, $Deadline)
								}
							} Else {
								If ($DelayedUpdate.Approve("Install", $ComputerGroup)) {
									[String]::Format("Approved for targetgroup {0}", $ComputerGroup.Name)
								}

							}
						}
					}
				}

			} 
			[String]::Format("Affected updates: {0}", $Count)
		} Else {
			[String]::Format("Affected updates: {0}", "Skipped Warning")
		}
		""
	} 
} Else {	
	"No Delayed Install Approval Rules found"
}