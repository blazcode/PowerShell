#######################################################################
#       Configure ESXi host network core dump
#######################################################################
# Author(s):   Corey Blaz
# Github:   https://github.com/blazcode
# Web:      https://vcorey.com

# Script Configuration
$vCenterFqdn = "vcf-mgmt1-vc1.lab.blaz.tech"
$netDumpServer = "10.0.1.20"
$netDumpPort = 6500
$vmKernelNic = "vmk0"

# No need to edit past here

$creds = Get-Credential
Connect-VIServer -Server $vCenterFqdn -Credential $creds
Write-Host ""

Write-Host "Checking hosts in vCenter: " -ForegroundColor Green -NoNewline
Write-Host $vCenterFqdn -ForegroundColor White
Write-Host ""

foreach ( $vmHost in Get-VMHost) {
    Write-Host "Configuring netdump on: " -ForegroundColor Green -NoNewline
    Write-Host $vmHost.Name -ForegroundColor White

    try {
        $esxcli = Get-EsxCli -VMHost $vmHost -V2

        # Need to send IP, Port, and interface first
        $args = $esxcli.system.coredump.network.set.CreateArgs()
        $args.serveripv4 = $netDumpServer
        $args.serverport = $netDumpPort
        $args.interfacename = $vmKernelNic
        $esxcli.system.coredump.network.set.Invoke($args) | Out-Null

        # Lastly, enable network core dump
        $args = $esxcli.system.coredump.network.set.CreateArgs()
        $args.enable = "true"
        $esxcli.system.coredump.network.set.Invoke($args) | Out-Null

        # Validate network core dump is enabled
        Write-Host $esxcli.system.coredump.network.check.Invoke() -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host ("ERROR: Failed to configure network core dump on $($vmHost.Name): $_") -ForegroundColor Red
    }
}

Disconnect-VIServer -Server $vCenterFqdn -Confirm:$False