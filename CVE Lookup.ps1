$CVEs = Import-Csv -Path /to/your.csv #Must be single column with "CVE" as a header

$output = @()

foreach ($CVE in $CVEs) {
    Write-host $CVE.CVE
    $CVEInfo = Invoke-WebRequest -Uri "https://cvedb.shodan.io/cve/$($CVE.CVE)" | ConvertFrom-Json
    
    $output += $CVEInfo | Select-Object cve_id, summary, cvss, cvss_version, cvss_v2, 
    cvss_v3, epss, ranking_epss, kev, propose_action, ransomware_campaign, 
    @{Name="references"; Expression={($_.references -join "; ")}}, published_time

    Start-Sleep -Milliseconds 2000 #Be kind
}

$output | export-csv -Path ./CVE-Detail.csv -IncludeTypeInformation

