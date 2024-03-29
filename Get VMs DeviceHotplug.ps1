$creds = Get-Credential

Connect-VIServer -Server vcsa-8x.corp.local -Credential $creds -Force

# Get all VMs -> Search for devices.hotplug
$VMs = Get-VM | Get-AdvancedSetting -Name "devices.hotplug"

# Create output variable
$output = @()

# Get all VMs and iterate through them, searching for devices.hotplug
Foreach ($VM in Get-VM) {
    if ($($VM | Get-AdvancedSetting -Name "devices.hotplug").Value) {
        $devicesHotplug = $true
    } else {
        $devicesHotplug = $false
    }

    $vmObject = New-Object -TypeName PSObject 
    $vmObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $VM.name
    $vmObject | Add-Member -MemberType NoteProperty -Name 'devicesHotplug' -Value $devicesHotplug

    $output += $vmObject
}

# This can be exported to .csv
$output | sort -Property devicesHotplug -Descending