##################################################################
####                                                          ####
####                 REMOTE INSTALL                           ####       
####                                                          ####
####             Writen by Felipe Binotto                     ####
####               Date: 01/05/10                             ####
####                                                          #### 
####                                                          ####
##################################################################



function remoteinstall {

	$returnvalue = (Get-WmiObject -ComputerName $address.Text -List | Where-Object -FilterScript {$_.Name -eq "win32_product"}).install($location.Text) | Select-Object -Property returnvalue
	if($returnvalue.returnvalue -eq "0")
	{		[Windows.Forms.MessageBox]::Show("Installation was successful!")}
	else{[Windows.Forms.MessageBox]::Show("Installation was not successful!")}
}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Form = New-Object System.Windows.Forms.Form

$Form.width = 500
$Form.height = 350
$Form.Text = "Remote Uninstall"
$Form.backcolor = "#5D8AA8"
$Form.maximumsize = New-Object System.Drawing.Size(500, 350)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
		{			remoteinstall}})
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
		{			$Form.Close()}})

$Button = new-object System.Windows.Forms.Button
$Button.Location = new-object System.Drawing.Size(180,200)
$Button.Size = new-object System.Drawing.Size(130,30)
$Button.Text = "Install!"
$Button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(255, 255, 192);
$Button.Image = [System.Drawing.Image]::FromFile("c:\mytools\gifs\lupa.ico")
$Button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft;
$button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Button.Add_Click({remoteinstall})

$Form.Controls.Add($Button)

$address = new-object System.Windows.Forms.TextBox
$address.Location = new-object System.Drawing.Size(65,60)
$address.Size = new-object System.Drawing.Size(100,20)

$Form.Controls.Add($address)

$addresslabel = new-object System.Windows.Forms.Label
$addresslabel.Location = new-object System.Drawing.Size(70,10)
$addresslabel.size = new-object System.Drawing.Size(100,50)
$addresslabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$addresslabel.Text = "Computer"
$Form.Controls.Add($addresslabel)

$locationlabel = new-object System.Windows.Forms.Label
$locationlabel.Location = new-object System.Drawing.Size(260,10)
$locationlabel.size = new-object System.Drawing.Size(200,50)
$locationlabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$locationlabel.Text = "MSI Location"
$Form.Controls.Add($locationlabel)

$location = new-object System.Windows.Forms.TextBox
$location.Location = new-object System.Drawing.Size(200,60)
$location.Size = new-object System.Drawing.Size(250,20)

$Form.Controls.Add($location)

$warning = new-object System.Windows.Forms.Label
$warning.Location = new-object System.Drawing.Size(200,90)
$warning.size = new-object System.Drawing.Size(200,50)
$warning.Font = new-object System.Drawing.Font("Microsoft Sans Serif",7)
$warning.Text = "Use UNC path `nFile must be in the target PC"
$Form.Controls.Add($warning)


$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()