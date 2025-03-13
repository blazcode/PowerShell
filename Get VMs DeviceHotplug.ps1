#######################################################################
#       vCenter VM devices.hotplug Report
#######################################################################
# Author(s):   Corey Blaz & Michael Gorka
# Github:   https://github.com/blazcode
# Web:      https://vcorey.com

# Connect to vCenter
$creds = Get-Credential
Connect-VIServer -Server vcsa-8x.corp.local -Credential $creds -Force

# Create output variable
$output = @()

# Get all VMs and iterate through them, searching for devices.hotplug
Foreach ($VM in Get-VM) {
    Write-Host "Checking: " $VM.name

    # Get-AdvancedSetting returns nothing at all if setting is unset, therefore must set to $null and update the value if the setting is configured
    $devicesHotplugSetting = $null
    $devicesHotplugSetting = $(Get-AdvancedSetting -Entity $VM -Name "devices.hotplug").Value

    if ($devicesHotplugSetting -ne $null) {
        $devicesHotplugValue = $devicesHotplugSetting
    } else {
        $devicesHotplugValue = "UNSET"
    }

    $vmObject = New-Object -TypeName PSObject 
    $vmObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $VM.name
    $vmObject | Add-Member -MemberType NoteProperty -Name 'devicesHotplug' -Value $devicesHotplugValue 

    $output += $vmObject
}

# This can be exported to .csv
$output | sort -Property devicesHotplug -Descending | Format-Table
$output | Export-Csv -Path C:\temp\report.csv -NoTypeInformation