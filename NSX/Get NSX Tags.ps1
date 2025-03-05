
$nsxtManager = "https://nsx-manager.example.com"
$username = "user"
$password = "supersecret"

$response = Invoke-RestMethod -Uri "$nsxtManager/api/v1/infra/tags" -Method Get -Headers @{
    "Authorization" = "Basic $( [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}"))) )"
    "Content-Type" = "application/json"
} -Body '{}' -SkipCertificateCheck

$output = @()

foreach ( $item in $response.results ) {
    $tagData= [PSCustomObject]@{
        "Tagged Objects Count" = $item.tagged_objects_count
        "Scope" = $item.scope
        "Tag" = $item.tag
    }

    $output += $tagData
}

$output

$output | Export-Csv -Path "/path/to/save/nsx-tags.csv" -NoTypeInformation