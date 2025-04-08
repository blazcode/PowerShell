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
        # Hash combined VM vCenter InstanceUUID and VM InstanceUUIDs to create unique ID
        $hasher = [System.Security.Cryptography.HashAlgorithm]::Create('sha256')
        $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($vCenterInstanceUUID + $vm.ExtensionData.Config.InstanceUuid))
        $globalIdSha = [System.BitConverter]::ToString($hash)

        $vmData = [PSCustomObject]@{
            vCenterName              = $vc.Name
            vCenterInstanceUUID      = $vCenterInstanceUUID 
            VM_Name                  = $vm.Name
            VM_MoRef                 = $vm.Id #VM MoRef
            VM_InstanceUUID          = $vm.ExtensionData.Config.InstanceUuid #VM InstanceUUID
            VM_GlobalUniqueId        = $vCenterInstanceUUID + " + " + $vm.ExtensionData.Config.InstanceUuid #Example for illustrative purposes
            VM_GlobalUniqueId_SHA256 = $globalIdSha.Replace('-', '')
        }

        $output += $vmData
    }
}

#Disconnect-VIServer * -Confirm:$false

# Display and export the output
$output | Format-Table -AutoSize
$output | Export-Csv -Path /Users/cblaz/Downloads/vm-unique-ids.csv -NoTypeInformation

