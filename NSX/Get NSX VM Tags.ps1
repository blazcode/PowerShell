$nsxtManager = "https://nsx-manager.example.com"
$username = "user"
$password = "supersecret"

$response = Invoke-RestMethod -Uri "$nsxtManager/api/v1/fabric/virtual-machines" -Method Get -Headers @{
    "Authorization" = "Basic $( [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}"))) )"
    "Content-Type" = "application/json"
} -Body '{}' -SkipCertificateCheck

$output = @()

foreach ($item in $response.results) {
    if ($item.tags) {
        $vmTags = ""

        foreach ($tag in $item.tags) {
            $vmTags += "Scope: " + $tag.scope + " Tag: " + $tag.tag + " "
        }
        
        $vmData= [PSCustomObject]@{
            "VM Name" = $item.display_name
            Tags = $vmTags
        }

        $output += $vmData
    }
}

$output

$output | Export-Csv -Path "/path/to/save/nsx-vm-tags.csv" -NoTypeInformation