#######################################################################
#       Check ESXi host network core dump configuration
#######################################################################
# Author(s):   Corey Blaz
# Github:   https://github.com/blazcode
# Web:      https://vcorey.com

# Script Configuration
$vCenterFqdn = "vcf-mgmt1-vc1.lab.blaz.tech"

$generateCsv = $true #or $false
$csvFileLocation = "/Users/cblaz/Downloads/vmHost-Network-Core-Dump-Status.csv" 

# No need to edit past here

$creds = Get-Credential
Connect-VIServer -Server $vCenterFqdn -Credential $creds
Write-Host ""

$output = @()

Write-Host "Checking hosts in vCenter: " -ForegroundColor Green -NoNewline
Write-Host $vCenterFqdn -ForegroundColor White
Write-Host ""

foreach ( $vmHost in Get-VMHost ) {
    $esxcli = Get-EsxCli -VMHost $vmHost -V2
    $coreDumpStatus = $esxcli.system.coredump.network.get.Invoke()

    Write-Host "--- " $vmHost.Name " ---" -ForegroundColor Yellow

    Write-Host "Enabled: " -ForegroundColor Green -NoNewline
    Write-Host $coreDumpStatus.Enabled -ForegroundColor White

    if ($coreDumpStatus.Enabled -eq 'true') {
        Write-Host "HostVNic: " -ForegroundColor Green -NoNewline
        Write-Host $coreDumpStatus.HostVNic -ForegroundColor White
        
        Write-Host "IsUsingIPV6: " -ForegroundColor Green -NoNewline
        Write-Host $coreDumpStatus.IsUsingIPV6 -ForegroundColor White

        Write-Host "NetworkServerIP: " -ForegroundColor Green -NoNewline
        Write-Host $coreDumpStatus.NetworkServerIP -ForegroundColor White

        Write-Host "NetworkServerPort: " -ForegroundColor Green -NoNewline
        Write-Host $coreDumpStatus.NetworkServerPort -ForegroundColor White     
    }

    Write-Host ""

    $coreDumpConfig= [PSCustomObject]@{
        "vmHost" = $vmHost.Name
        "Enabled" = $coreDumpStatus.Enabled
        "HostVNic" = $coreDumpStatus.HostVNic
        "IsUsingIPV6" = $coreDumpStatus.IsUsingIPV6
        "NetworkServerIP" = $coreDumpStatus.NetworkServerIP
        "NetworkServerPort" = $coreDumpStatus.NetworkServerPort
    }

    $output += $coreDumpConfig
}

if ($generateCsv) {
    try {
        $output | Export-Csv -Path $csvFileLocation -NoTypeInformation
    } catch {
        Write-Host "Error generating .csv file:" $_  -ForegroundColor Red
    }
}

Disconnect-VIServer -Server $vCenterFqdn -Confirm:$False