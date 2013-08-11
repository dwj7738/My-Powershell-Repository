## ==================================================================================
## Title       : Delete Computer Object from AD in a Multi-Domain environment
## Description : Deletes a computer object from the AD after allowing selection of
##				 the correct domain in a  multi-domain environment.
## Author      : C.Perry
## Date        : 14/2/2012
## Input       : 	
## Output      : 
## Usage	   : PS> .\DeleteComputerObject.ps1
## Notes	   :
## Tag		   : Forms, .NET Framework, AD
## Change log  :
## ==================================================================================
## INITIALIZATION SECTION ##
CLS
$x = $null
$y = $null
$domain = $null
# Error display on console
Function ErrorDisplay ([string]$strErrorMsg)
{
	write-host -backgroundcolor yellow -foregroundcolor black $strErrorMsg ; 
}
# Displays an Input Form to input the computer object
Function InputForm ([string]$strFormText, [string]$strLabelText)
{
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = $strFormText
	$objForm.Size = New-Object System.Drawing.Size(300,200) 
	$objForm.StartPosition = "CenterScreen"

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
			{				$x = $objTextBox.Text;$objForm.Close()}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
			{				$objForm.Close()}})

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Size(75,120)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = "OK"
	$OKButton.Add_Click({$x = $objTextBox.Text;$objForm.Close()})
	$objForm.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(150,120)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(10,20) 
	$objLabel.Size = New-Object System.Drawing.Size(280,20) 
	$objLabel.Text = $strLabelText
	$objForm.Controls.Add($objLabel) 

	$objTextBox = New-Object System.Windows.Forms.TextBox 
	$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
	$objTextBox.Size = New-Object System.Drawing.Size(250,40) 
	$objForm.Controls.Add($objTextBox) 
	$objForm.Controls.($objTextBox)

	$objForm.Topmost = $True
	#make cursor appear in textbox first
	$handler = {$objForm.ActiveControl = $objTextBox}
	$objForm.add_Load($handler)
	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()

	return $x #  Returns the computer name string
}
# Information Display Form
Function DisplayForm ([string]$strFormText, [string]$strLabelText,[string]$strBackColor)
{

	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
	$FontBold = new-object System.Drawing.Font("Arial",8,[Drawing.FontStyle]'Bold' )

	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = $strFormText
	$objForm.Backcolor = $strBackColor
	$objForm.Size = New-Object System.Drawing.Size(300,200) 
	$objForm.StartPosition = "CenterScreen"

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
			{				$y = "True";$objForm.Close()}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
			{				$y = "False";$objForm.Close()}})

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Size(75,120)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = "OK"
	$OKButton.Add_Click({$y = "True";$objForm.Close()})
	$objForm.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(150,120)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$y = "False";$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(10,20) 
	$objLabel.Size = New-Object System.Drawing.Size(280,50) 
	$objLabel.Text = $strLabelText
	$objLabel.Font = $FontBold
	$objForm.Controls.Add($objLabel) 
	$objForm.Topmost = $True
	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()

	return $y #  Returns a confirmation
}
# Choose Item from List
Function Select-Item 
{	<# 
    .Synopsis        Allows the user to select simple items, returns a number to indicate the selected item. 
    .Description 
        Produces a list on the screen with a caption followed by a message, the options are then
		displayed one after the other, and the user can one. 
        Note that help text is not supported in this version. 
    .Example 
        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",           "&Enable Remote Desktop","&Cancel"  -default 1       Will display the following 
          Configuring RemoteDesktop           Do you want to:           [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 
    .Parameter Choicelist 
        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 
    .Parameter Default 
        The zero based item in the array which will be the default choice if the user hits enter. 
    .Parameter Caption 
        The First line of text displayed 
    .Parameter Message 
        The Second line of text displayed     #> 
	Param( [String[]]$choiceList, 
		[String]$Caption, 
		[String]$Message, 
		[int]$default
	) 
	$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
	$choiceList | foreach { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 
	$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default) 
} 

## PROCESS SECTION ##
# Do until user Cancels
While ($domain -ne "Cancel")
{
	TRY
	{		#TRY
		$domain = select-item -Caption "Domain Selection for AD Server Deletion" -Message "Please select a domain: " `
		-choice "&1 DomainA", "&2 DomainB", "&3 DomainC", "&4 DomainD", "&5 DomainE", "&6 Cancel" -default 5
		switch ($domain) 
		{
			0 {$domain = "DomainA"} 
			1 {$domain = "DomainB"} 
			2 {$domain = "DomainC"} 
			3 {$domain = "DomainD"} 
			4 {$domain = "DomainE"} 
			5 {$domain = "Cancel"} 
			default {$domain = "Cancel"}
		}
		If ($domain -eq "Cancel")
		{
			echo "Cancel selected"
			exit
		}
		$HeaderTxt = "Data Entry Form"
		$LabelTxt = "Please enter the computer name below:"
		[string]$x = InputForm $HeaderTxt $LabelTxt 
		$e = $x.TrimStart(" ")
		#create the domain context object
		$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
		#get the domain object
		$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
		#$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()   
		#$dom # Debug line
		$root = $dom.GetDirectoryEntry() 
		#$root  #Debug line
		$search = [System.DirectoryServices.DirectorySearcher]$root 
		$search.filter = "(&(objectclass=computer)(name=*$e*))" 
		#$search.Filter #Debug line
		$ComputerToDelete = $search.findall() | %{$_.GetDirectoryEntry() }
		If ($ComputerToDelete -eq $null)
		{			#IFnull
			$ErrorTitle = "Computer " + $e + " Not Found in the AD"
			$ErrorMsg = "Computer Not Found"
			$BackColour = "Yellow"
			ErrorDisplay $ErrorTitle $ErrorMsg
			$y = Displayform $ErrorMsg $ErrorTitle $BackColour
		}#endIfNull
		Else
		{			#ElseFound
			#display confirmation form
			$HeaderTxt = "Fat Finger Checker Form"
			$LabelTxt = "Is this the computer you want to delete?  `n`n " + $ComputerToDelete.Name 
			$y = DisplayForm $HeaderTxt $LabelTxt 
			#Delete computer object from AD
			$search.findall() | %{$_.GetDirectoryEntry() } | %{$_.DeleteObject(0)}
			#Test to make sure it is deleted
			$ComputerToDelete = $search.findall() | %{$_.GetDirectoryEntry() }
			If ($ComputerToDelete -eq $null)
			{				#IFnull
				$LabelTxt = "Computer " + $e + " deleted from AD."
				$HeaderTxt = "Computer Object Deleted"
				$BackColour = "Green"
				$y = Displayform $HeaderTxt $LabelTxt $BackColour
			}#endIfNull
			Else
			{				#ElseFound
				#display confirmation form
				$LabelTxt = "Computer " + $e + " was not deleted from AD."
				$HeaderTxt = "Error Deleting Computer Object"
				$BackColour = "Red"
				ErrorDisplay $LabelTxt 
				$y = DisplayForm $HeaderTxt $LabelTxt $BackColour 
			}#endElseFound
		}#endElseFound
	}#endTRY
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
		}#endIfExc
		if ($exceptionType -match 'System.Management.Automation.Host.PromptingException')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
			$domain = "Cancel"
			exit
		}#endIfExc
		if ($exceptionType -match 'System.UnauthorizedAccessException')
		{			#IfEx
			$UnauthorizedExceptionType = $Server + " Access denied - insufficent privileges"
			# write-host "Exception: $exceptionType"
			write-host -backgroundcolor red "UnauthorizedException: $UnauthorizedExceptionType"
		}#endIfEx
		if ($exceptionType -match 'System.Management.Automation.RuntimeException')
		{			#IfExc
			# Attempt to access an non existant array, output is suppressed
			write-host -backgroundcolor cyan -foregroundcolor black "$Server - A runtime exception occured: " $_.Exception.Message; 
		}#endIfExc
	}#end Catch
}#end While