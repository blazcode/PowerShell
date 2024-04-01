﻿#######################################################################
#       vCenter VM devices.hotplug Report
#######################################################################
# Author:   Corey Blaz
# Github:   https://github.com/blazcode
# Web:      https://coreyblaz.com

# Connect to vCenter
$creds = Get-Credential
Connect-VIServer -Server vcsa-8x.corp.local -Credential $creds -Force

# Create output variable
$output = @()

# Get all VMs and iterate through them, searching for devices.hotplug
Foreach ($VM in Get-VM) {
    Write-Host "Checking: " $VM.name

    $vmObject = New-Object -TypeName PSObject 
    $vmObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $VM.name
    $vmObject | Add-Member -MemberType NoteProperty -Name 'devicesHotplug' -Value $($VM | Get-AdvancedSetting -Name "devices.hotplug").Value 

    $output += $vmObject
}

# This can be exported to .csv
$output | sort -Property devicesHotplug -Descending
#$output | Export-Csv -Path C:\temp\report.csv 