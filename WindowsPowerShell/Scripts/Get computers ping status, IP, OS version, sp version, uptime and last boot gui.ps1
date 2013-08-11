Param ([switch]$NoWarning,[switch]$Debug)

If ($Debug) {
    #enable debug messages if -debug is specified
    $debugPreference="Continue"
}

If ($NoWarning) {
    #turn off warning messages
    $WarningPreference="SilentlyContinue"
}

function Ping-Host {
  Param([string]$computername=$(Throw "You must specify a computername."))
  
  Write-Debug "In Ping-Host function"
  
  $query="Select * from Win32_PingStatus where address='$computername'"
  
  $wmi=Get-WmiObject -query $query
  write $wmi
}

function Get-OS {
  Param([string]$computername=$(Throw "You must specify a computername."))
  Write-Debug "In Get-OS Function"
  $wmi=Get-WmiObject Win32_OperatingSystem -computername $computername -ea stop
  
  write $wmi

}


#Generated Form Function
function GenerateForm {

#region Import the Assemblies
Write-Debug "Loading Assemblies"
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
#endregion

#region Generated Form Objects
Write-Debug "Creating form objects"
$form1 = New-Object System.Windows.Forms.Form
$lblRefreshInterval = New-Object System.Windows.Forms.Label
$numInterval = New-Object System.Windows.Forms.NumericUpDown
$btnQuit = New-Object System.Windows.Forms.Button
$btnGo = New-Object System.Windows.Forms.Button
$dataGridView = New-Object System.Windows.Forms.DataGridView
$label2 = New-Object System.Windows.Forms.Label
$statusBar = New-Object System.Windows.Forms.StatusBar
$txtComputerList = New-Object System.Windows.Forms.TextBox
$timer1 = New-Object System.Windows.Forms.Timer
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------

$LaunchCompMgmt= 
{
    #only launch computer management if a cell in the Computername 
    #column was selected.
    $c=$dataGridView.CurrentCell.columnindex
    $colHeader=$dataGridView.columns[$c].name
    if ($colHeader -eq "Computername") {
        $computer=$dataGridView.CurrentCell.Value
        Write-Debug ("Launch computer management for {0}" -f $computer.toUpper())
        compmgmt.msc /computer:$computer
    }
} #end Launch Computer Management script block

$GetStatus= 
{

 Trap {
    	Write-Debug "Error trapped in GetStatus script block"
    	Write-Warning $_.Exception.message
        Continue
    }
    
    #stop the timer while data is refreshed
    Write-Debug "Stop the timer"
    $timer1.stop()

    Write-Debug ("Getting content from {0}" -f $txtComputerlist.Text)
    if ($computers) {Clear-Variable computers}
    
    #clear the table
    $dataGridView.DataSource=$Null
    
    $computers=Get-Content $txtComputerList.Text -ea stop | sort 
    
    if ($computers) {
       
        $statusBar.Text = ("Querying computers from {0}" -f $txtComputerList.Text)
        $form1.Refresh
        
        #create an array for griddata
        Write-Debug "Create `$griddata"
        $griddata=@()
        #create a custom object
        
        foreach ($computer in $computers) {
          Write-Debug "Pinging $computer"
          $statusBar.Text=("Pinging {0}" -f $computer.toUpper())
          Write-Debug "Creating `$obj"
          $obj=New-Object PSobject
          Write-Debug "Adding Computername property"
          $obj | Add-Member Noteproperty Computername $computer.ToUpper()
          
          #ping the computer
          if ($pingResult) {
            #clear PingResult if it has a left over value
            Clear-Variable pingResult
            }
          $pingResult=Ping-Host $computer
          Write-Debug "Pinged status code is $($pingResult.Statuscode)"
      
          if ($pingResult.StatusCode -eq 0) {
               
               $obj | Add-Member Noteproperty Pinged "Yes"
               Write-Debug "Adding $($pingresult.ProtocolAddress)"
               $obj | Add-Member Noteproperty IP $pingResult.ProtocolAddress
               
               #get remaining information via WMI
               Trap {
                #define a trap to handle any WMI errors
                Write-Warning ("There was a problem with {0}" -f $computer.toUpper())
                Write-Warning $_.Exception.GetType().FullName
                Write-Warning $_.Exception.message
                Continue
                }
               		
                if ($os) {
                    #clear OS if it has a left over value
                    Clear-Variable os
                }
               $os=Get-OS $computer
               if ($os) {
                   $lastboot=$os.ConvertToDateTime($os.lastbootuptime)
                   Write-Debug "Adding $lastboot"
                   $uptime=((get-date) - ($os.ConvertToDateTime($os.lastbootuptime))).tostring()
                   Write-Debug "Adding $uptime"
                   $osname=$os.Caption
                   Write-Debug "Adding $osname"
                   $servicepack=$os.CSDVersion
                   Write-Debug "Adding $servicepack"
                   
                   $obj | Add-Member Noteproperty OS $osname
                   $obj | Add-Member Noteproperty ServicePack $servicepack
                   $obj | Add-Member Noteproperty Uptime $uptime
                   $obj | Add-Member Noteproperty LastBoot $lastboot
               }
               else {
               Write-Debug "Setting properties to N/A"
                   $obj | Add-Member Noteproperty OS "N/A"
                   $obj | Add-Member Noteproperty ServicePack "N/A"
                   $obj | Add-Member Noteproperty Uptime "N/A"
                   $obj | Add-Member Noteproperty LastBoot "N/A"
               }
          }
          else {
                Write-Debug "Ping failed"
                Write-Debug "Setting properties to N/A"

               $obj | Add-Member Noteproperty Pinged "No"
               $obj | Add-Member Noteproperty IP "N/A"
               $obj | Add-Member Noteproperty OS "N/A"
               $obj | Add-Member Noteproperty ServicePack "N/A"
               $obj | Add-Member Noteproperty Uptime "N/A"
               $obj | Add-Member Noteproperty LastBoot "N/A"
          }
        
        	#Add the object to griddata
            	Write-Debug "Adding `$obj to `$griddata"
            	$griddata+=$obj

		
        } #end foreach
        
        Write-Debug "Creating ArrayList"   
        $array= New-Object System.Collections.ArrayList
        
        Write-Debug "Adding `$griddata to `$arry"
        $array.AddRange($griddata)
        $DataGridView.DataSource = $array
        #find unpingable computer rows
        Write-Debug "Searching for non-pingable computers"
        $c=$dataGridView.RowCount
        for ($x=0;$x -lt $c;$x++) {
            for ($y=0;$y -lt $dataGridView.Rows[$x].Cells.Count;$y++) {
                $value = $dataGridView.Rows[$x].Cells[$y].Value
                if ($value -eq "No") {
                #if Pinged cell = No change the row font color
                Write-Debug "Changing color on row $x"
                $dataGridView.rows[$x].DefaultCellStyle.Forecolor=[System.Drawing.Color]::FromArgb(255,255,0,0)
                }
            }
        }
        Write-Debug "Setting status bar text"
        $statusBar.Text=("Ready. Last updated {0}" -f (Get-Date))

    }
    else {
        Write-Debug "Setting status bar text"
        $statusBar.Text=("Failed to find {0}" -f $txtComputerList.text)
    }
   
   #set the timer interval
    $interval=$numInterval.value -as [int]
    Write-Debug "Interval is $interval"
    #interval must be in milliseconds
    $timer1.Interval = ($interval * 60000) #1 minute time interval
    Write-Debug ("Timer interval calculated at {0} milliseconds" -f $timer1.Interval )
    #start the timer
    Write-Debug "Starting timer"
    $timer1.Start()
    
    Write-Debug "Refresh form"
    $form1.Refresh()
   
} #End GetStatus scriptblock

$Quit= 
{
    Write-Debug "closing the form"
    $form1.Close()
} #End Quit scriptblock

#----------------------------------------------
#region Generated Form Code
$form1.Name = 'form1'
$form1.Text = 'Display Computer Status'
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 890
$System_Drawing_Size.Height = 359
$form1.ClientSize = $System_Drawing_Size
$form1.StartPosition = 1
$form1.BackColor = [System.Drawing.Color]::FromArgb(255,185,209,234)

$lblRefreshInterval.Text = 'Refresh Interval (min)'

$lblRefreshInterval.DataBindings.DefaultDataSourceUpdateMode = 0
$lblRefreshInterval.TabIndex = 10
$lblRefreshInterval.TextAlign = 64
#$lblRefreshInterval.Anchor = 9
$lblRefreshInterval.Name = 'lblRefreshInterval'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 128
$System_Drawing_Size.Height = 23
$lblRefreshInterval.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 440
$System_Drawing_Point.Y = 28
$lblRefreshInterval.Location = $System_Drawing_Point

$form1.Controls.Add($lblRefreshInterval)

#$numInterval.Anchor = 9
$numInterval.DataBindings.DefaultDataSourceUpdateMode = 0
$numInterval.Name = 'numInterval'
$numInterval.Value = 10
$numInterval.TabIndex = 9
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 51
$System_Drawing_Size.Height = 20
$numInterval.Size = $System_Drawing_Size
$numInterval.Maximum = 60
$numInterval.Minimum = 1
$numInterval.Increment = 2
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 575
$System_Drawing_Point.Y = 30
$numInterval.Location = $System_Drawing_Point
# $numInterval.add_ValueChanged($GetStatus)

$form1.Controls.Add($numInterval)


$btnQuit.UseVisualStyleBackColor = $True
$btnQuit.Text = 'Close'

$btnQuit.DataBindings.DefaultDataSourceUpdateMode = 0
$btnQuit.TabIndex = 2
$btnQuit.Name = 'btnQuit'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$btnQuit.Size = $System_Drawing_Size
#$btnQuit.Anchor = 9
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 341
$System_Drawing_Point.Y = 30
$btnQuit.Location = $System_Drawing_Point
$btnQuit.add_Click($Quit)

$form1.Controls.Add($btnQuit)


$btnGo.UseVisualStyleBackColor = $True
$btnGo.Text = 'Get Status'

$btnGo.DataBindings.DefaultDataSourceUpdateMode = 0
$btnGo.TabIndex = 1
$btnGo.Name = 'btnGo'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$btnGo.Size = $System_Drawing_Size
#$btnGo.Anchor = 9
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 233
$System_Drawing_Point.Y = 31
$btnGo.Location = $System_Drawing_Point
$btnGo.add_Click($GetStatus)

$form1.Controls.Add($btnGo)

$dataGridView.RowTemplate.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,0,128,0)
$dataGridView.Name = 'dataGridView'
$dataGridView.DataBindings.DefaultDataSourceUpdateMode = 0
$dataGridView.ReadOnly = $True
$dataGridView.AllowUserToDeleteRows = $False
$dataGridView.RowHeadersVisible = $False
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 870
$System_Drawing_Size.Height = 260
$dataGridView.Size = $System_Drawing_Size
$dataGridView.TabIndex = 8
$dataGridView.Anchor = 15
$dataGridView.AutoSizeColumnsMode = 16



$dataGridView.AllowUserToAddRows = $False
$dataGridView.ColumnHeadersHeightSizeMode = 2
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 70
$dataGridView.Location = $System_Drawing_Point
$dataGridView.AllowUserToOrderColumns = $True
$dataGridView.add_CellContentDoubleClick($LaunchCompMgmt)
#$dataGridView.AutoResizeColumns([System.Windows.Forms.DataGridViewAutoSizeColumnsMode.AllCells]::AllCells)
#$DataGridViewAutoSizeColumnsMode.AllCells

$form1.Controls.Add($dataGridView)

$label2.Text = 'Enter the name and path of a text file with your list of computer names: (One name per line)'

$label2.DataBindings.DefaultDataSourceUpdateMode = 0
$label2.TabIndex = 7
$label2.Name = 'label2'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 490
$System_Drawing_Size.Height = 23
$label2.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 7
$label2.Location = $System_Drawing_Point

$form1.Controls.Add($label2)

$statusBar.Name = 'statusBar'
$statusBar.DataBindings.DefaultDataSourceUpdateMode = 0
$statusBar.TabIndex = 4
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 428
$System_Drawing_Size.Height = 22
$statusBar.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 337
$statusBar.Location = $System_Drawing_Point
$statusBar.Text = 'Ready'

$form1.Controls.Add($statusBar)

$txtComputerList.Text = 'c:\test\computers.txt'
$txtComputerList.Name = 'txtComputerList'
$txtComputerList.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 198
$System_Drawing_Size.Height = 20
$txtComputerList.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 33
$txtComputerList.Location = $System_Drawing_Point
$txtComputerList.DataBindings.DefaultDataSourceUpdateMode = 0

$form1.Controls.Add($txtComputerList)


#endregion Generated Form Code

Write-Debug "Adding script block to timer"
#add the script block to execute when the timer interval expires
$timer1.add_Tick($GetStatus)

#Show the Form
Write-Debug "ShowDialog()"
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
Write-Debug "Call GenerateForm"
GenerateForm
