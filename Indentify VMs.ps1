#######################################################################
#       Identify VMs Uniquely Across Multiple vCenters
#######################################################################
# Author(s):   Corey Blaz
# Github:   https://github.com/blazcode
# Web:      https://vcorey.com

# Connect to vCenter(s)
$creds = Get-Credential
Connect-VIServer -Server vcsa.example.com -Credential $creds -Force
Connect-VIServer -Server vcsa2.example.com -Credential $creds -Force

$output = @()

foreach ($vc in $global:DefaultVIServers) {
    # Get the vCenter InstanceUUID
    $vCenterInstanceUUID = ($vc.ExtensionData.Content.About.InstanceUuid)

    $vms = Get-VM -Server $vc

    foreach ($vm in $vms) {
        $vmData = [PSCustomObject]@{
            vCenterName         = $vc.Name
            vCenterInstanceUUID = $vCenterInstanceUUID 
            VM_Name              = $vm.Name
            VM_MoRef            = $vm.Id #VM MoRef
            VM_InstanceUUID     = $vm.ExtensionData.Config.InstanceUuid #VM InstanceUUID
            VM_GlobalUniqueId   = $vCenterInstanceUUID + " + " + $vm.ExtensionData.Config.InstanceUuid #Example
        }
        
        $output += $vmData
    }
}

Disconnect-VIServer * -Confirm:$false

# Display and export the output
$output | Format-Table -AutoSize
$output | Export-Csv -Path /Users/cblaz/Downloads/vm-unique-ids.csv -NoTypeInformation

