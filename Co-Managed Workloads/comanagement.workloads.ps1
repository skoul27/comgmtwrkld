[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$RSRID
)

function Load-Form {
	$Form.Controls.Add($ResultsGrid)
    $Form.Add_Shown({Get-DeviceComplianceStatus})
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()
}
# Get the Site Code
function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

# Convert WMI Time
Function Get-NormalDateTime {
 	param(
    	$WMIDateTime
    )
	$NormalDateTime = [management.managementDateTimeConverter]::ToDateTime($WMIDateTime)
	return $NormalDateTime
}
# Get Device Update Compliance Status
function Get-DeviceComplianceStatus {
$Data=Get-WmiObject -computername $SiteServer -namespace root\SMS\site_$(Get-CMSiteCode) -Query "select co.name,sys.LastLogonUserName,cdr.ClientVersion,cdr.LastPolicyRequest,cdr.LastHardwareScan,
co.ComgmtPolicyPresent,co.HybridAADJoined,co.AADJoined,co.MDMWorkloads
From SMS_Client_ComanagementState co
inner join SMS_CombinedDeviceResources cdr on cdr.MachineID=co.ResourceID
inner join sms_r_system sys on sys.resourceid=co.resourceid
where co.resourceid='$RSRID'"
#$results = @()
foreach ($update in $data)
{
$name=$update.co.Name
$LastLogonUserName=$update.sys.LastLogonUserName
$LastPolicyRequest=Get-NormalDateTime $update.cdr.LastPolicyRequest
$LastHardwareScan=Get-NormalDateTime $update.cdr.LastHardwareScan
$HybridAADJoined= $update.co.HybridAADJoined
$AADJoined=$update.co.AADJoined
$ComgmtPolicyPresent=$update.co.ComgmtPolicyPresent
$workload = switch ( $update.co.mdmworkloads )
{
#8193 {'Co-management is enabled without any workload applied'}
2 {'2-Compliance policies'}
4 {'4-Resource access Policies'}
8 {'8 -Device Configuration'}
16 {'16-Windows Updates Policies'}
4128 {'4128-Endpoint Protection'}
64 {'64-Client apps'}
128 {'128-Office Click-to-run apps'}
12543 {'12543-Client Apps,Device Configuration,Office Click-to-Run Apps,Windows Updates Policies,Resource access Policies,Compliance Policies,Endpoint Protection'}
8193 {'8193-Not Co-Managed'}
}
write-host $update.co.mdmworkloads
$RowIndex = $ResultsGrid.Rows.Add($name,$LastLogonUserName,$LastPolicyRequest,$HybridAADJoined,$AADJoined,$ComgmtPolicyPresent,$workload)
		If($workload -eq "Not Co-Managed")
		 {
		   $ResultsGrid.Rows.Item($RowIndex).DefaultCellStyle.BackColor = "Red"
		 }
		}
}

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(1400,200)  
$Form.MinimumSize = New-Object System.Drawing.Size(1400,200)
$Form.MaximumSize = New-Object System.Drawing.Size (1400,200)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Co-Mgmt Workloads" #MadeByShivamKoulA807812
$Form.ControlBox = $true
$Form.TopMost = $true
$Form.AutoSizeMode = "GrowAndShrink"
$Form.StartPosition = "CenterScreen"

# DataGriView
$ResultsGrid = New-Object System.Windows.Forms.DataGridView
$ResultsGrid.Location = New-Object System.Drawing.Size(20,30)
$ResultsGrid.Size = New-Object System.Drawing.Size(1350,170)
$ResultsGrid.ColumnCount = 7
$ResultsGrid.ColumnHeadersVisible = $true
$ResultsGrid.Columns[0].Name = "Name"
$ResultsGrid.Columns[0].AutoSizeMode = "Fill"
$ResultsGrid.Columns[1].Name = "UserName"
$ResultsGrid.Columns[1].AutoSizeMode = "Fill"
$ResultsGrid.Columns[2].Name = "LastPolicyRequest"
$ResultsGrid.Columns[2].AutoSizeMode = "Fill"
$ResultsGrid.Columns[3].Name = "HybridAADJoined"
$ResultsGrid.Columns[3].AutoSizeMode = "Fill"
$ResultsGrid.Columns[4].Name = "AADJoined"
$ResultsGrid.Columns[4].AutoSizeMode = "Fill"
$ResultsGrid.Columns[5].Name = "ComgmtPolicyPresent"
$ResultsGrid.Columns[5].AutoSizeMode = "Fill"
$ResultsGrid.Columns[6].Name = "Workload"
$ResultsGrid.Columns[6].AutoSizeMode = "Fill"
$ResultsGrid.AllowUserToAddRows = $false
$ResultsGrid.AllowUserToDeleteRows = $false
$ResultsGrid.ReadOnly = $True
#$ResultsGrid.ColumnHeadersHeightSizeMode = "DisableResizing"
#$ResultsGrid.RowHeadersWidthSizeMode = "DisableResizing"

# Load form
Load-Form