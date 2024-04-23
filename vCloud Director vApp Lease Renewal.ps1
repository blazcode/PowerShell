#### vCloud Director vApp Lease Renewal ###
#
# Author: Corey Blaz
#
# ------ References ------
# API versions: https://cloud-amer01.psgcl.vmware.com/api/versions
# API ref: https://developer.vmware.com/apis/vmware-cloud-director/v37.2/


# ------ Script Configuration ------
# vCloud Director environment
$vcd = "https://vcd.example.com" # Leave off trailing /, i.e.: https://vcd.example.com
$tenant = "workload" # I.e.: https://vcd.example.com/tenant/<this value>

# vCloud Director environment API key - 
$apiKey = ""

# vAPP IDs - I.e.: https://vcd.example.com/tenant/<tenant name>/vdcs/dca7041a-2ac4-46ce-8574-3392442cdedf/vapp/<this value>/general
$vApps = @(
    "vapp-11111111-2222-3333-4444-555555555555",
    "vapp-11111111-2222-3333-4444-555555555555"
)
# Define the new lease settings (in seconds)
$newLeaseSeconds = 1209600 # 14 days
$newStorageLeaseSeconds = 2592000 # 30 days

# Google Chat notification preferences
$gchatNotify = $true
$gchatWebhook = '' # Webhook URL

# ------ End Script Configuration ------


# ------ Login to vCloud Director Tenant ------
# Define the authentication endpoint URL
$authUrl = $vcd + "/oauth/tenant/" + $tenant + "/token"

# Construct the body for the token request
$body = @{
    grant_type = "refresh_token"
    refresh_token = $apiKey
}

# Construct the headers
$headers = @{
    "Accept" = "application/json"
    "Content-Type" = "application/x-www-form-urlencoded"
}

# Make the POST request to authenticate and retrieve the bearer token
try {
    $response = Invoke-RestMethod -Uri $authUrl -Headers $headers -Method Post -Body $body
    Write-Host "Obtained token"
} catch {
    Write-host -f red "Encountered Error:"$_.Exception.Message
}
# Extract the bearer token from the response
$token = "Bearer " + $response.access_token

# ------ Renew vAPP Lease(s) ------
$results = @()

# Construct the headers
$headers = @{
    "Accept" = "application/*+xml;version=37.2"
    "Authorization" = $token
    "Content-Type" = "application/vnd.vmware.vcloud.leaseSettingsSection+xml"
}

#leaseSettingsSection ref: https://developer.vmware.com/apis/1601/doc//operations/GET-LeaseSettingsSection-vApp.html
foreach ($vApp in $vApps) {
    $leaseApiUrl = $vcd + "/api/vApp/" + $vApp + "/leaseSettingsSection"

    $body = @"
<?xml version="1.0" encoding="UTF-8"?><vcloud:LeaseSettingsSection
xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1"
xmlns:vcloud="http://www.vmware.com/vcloud/v1.5"
href="$leaseApiUrl"
ovf:required="false"
type="application/vnd.vmware.vcloud.leaseSettingsSection+xml">
<ovf:Info>Lease settings section</ovf:Info>
<vcloud:Link
    href="$leaseApiUrl"
    rel="edit"
    type="application/vnd.vmware.vcloud.leaseSettingsSection+xml"/>
<vcloud:DeploymentLeaseInSeconds>$newLeaseSeconds</vcloud:DeploymentLeaseInSeconds>
<vcloud:StorageLeaseInSeconds>$newStorageLeaseSeconds</vcloud:StorageLeaseInSeconds>
</vcloud:LeaseSettingsSection>
"@

    try {
        Write-Host "Submitting renewal for:" $vApp
        $response = Invoke-RestMethod -Uri $leaseApiUrl -Headers $headers -Method Put -Body $body

        $tasksObj = [PSCustomObject]@{}
        $tasksObj | Add-Member -MemberType NoteProperty -Name 'Operation' -Value $response.Task.operation
        $tasksObj | Add-Member -MemberType NoteProperty -Name 'href' -Value $response.Task.href
        $tasksObj | Add-Member -MemberType NoteProperty -Name 'status' -Value $response.Task.status
        $results += $tasksObj
    } catch {
        Write-host -f red "Encountered Error:"$_.Exception.Message
    }
}

# ------ Send Google Chat Notification(s) ------
if($gchatNotify) {
    Foreach ($task in $results) {
        Write-Host "Checking status of task: " $task.Operation
        
        $headers = @{
            "Accept" = "application/*+xml;version=37.2"
            "Authorization" = $token
        }
        $response = Invoke-RestMethod -Uri $task.href -Headers $headers -Method Get

        while ($response.Task.status -ne "success") {
            Write-Host "..."
            Start-Sleep -Seconds 5
            $response = Invoke-RestMethod -Uri $task.href -Headers $headers -Method Get
        }

        if  ($response.Task.status -eq "success") {
            $messageBody = @{
                cards = @(
                    @{
                        header = @{
                            title    = "vApp Lease Renewal"
                        }
                        sections = @(
                            @{
                                widgets = @(
                                    @{
                                        keyValue = @{
                                            topLabel         = "Task:"
                                            content          = "$($response.Task.operation)"
                                            contentMultiline = $true
                                        }
                                    }
                                    @{
                                        keyValue = @{
                                            topLabel         = "Status:"
                                            content          = "$($response.Task.status)"
                                            contentMultiline = $true
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }
                
            $jsonMessage = $messageBody | ConvertTo-Json -Depth 10
        
            Write-Host "Sending Google Chat success notification for:" $task.Operation

            # Send the message
            $response = Invoke-RestMethod -Uri $gchatWebhook -Method Post -Body $jsonMessage -ContentType "application/json"
        }
    }
}

# ------ Job Done ------
Write-Host "Complete!"