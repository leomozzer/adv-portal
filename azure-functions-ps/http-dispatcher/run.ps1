using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$requestBody = $Request.RawBody  | ConvertFrom-Json

if (($requestBody.location -split " ").Count -eq 2) {
    $locationShort = ($requestBody.location -split " ")[0][0] + ($requestBody.location -split " ")[1].Substring(0, 2)
}
else {
    $locationShort = $requestBody.location.Substring(0, 3)
}
if ($requestBody.resourceGroupName) {
    $resourceGroupName = $requestBody.resourceGroupName
}
else {
    $resourceGroupName = "rg-$($locationShort.ToLower())-$($requestBody.vmName)"
}
switch ($requestBody.actionType) {
    "CreateAzVm" {
        $message = @{
            "vmName"                      = $requestBody.vmName
            "location"                    = $requestBody.location
            "resourceGroupName"           = $resourceGroupName
            "virtualNetworkResourceGroup" = $requestBody.virtualNetworkResourceGroup
            "virtualNetworkName"          = $requestBody.virtualNetworkName
            "subnetName"                  = $requestBody.subnetName
            "nicName"                     = "nic-$($requestBody.vmName)"
            "queueOrder"                  = @("create-nic", "create-azvm", "join-domain")
            "ordersCompleted"             = @()
            "actionType"                  = $requestBody.actionType
        }
        # Convert the hashtable to a JSON string
        $jsonMessage = $message | ConvertTo-Json
        Write-Output $jsonMessage
        $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
        $context = New-AzStorageContext -StorageAccountName "staeusavd01" -StorageAccountKey $env:StorageAccountKey
        Write-Output $queueMessage
        $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
        $queue.CloudQueue.AddMessage($queueMessage)
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Message added to the queue."
        }
        
        # Return the response
        $res
    }
    "DomainJoin" { 
        $message = @{
            "vmName"                      = $requestBody.vmName
            "location"                    = $requestBody.location
            "resourceGroupName"           = "rg-$($locationShort.ToLower())-$($requestBody.vmName)"
            "virtualNetworkResourceGroup" = $requestBody.virtualNetworkResourceGroup
            "virtualNetworkName"          = $requestBody.virtualNetworkName
            "subnetName"                  = $requestBody.subnetName
            "nicName"                     = "nic-$($requestBody.vmName)"
            "queueOrder"                  = @("create-rg", "create-nic", "create-azvm", "join-domain")
            "ordersCompleted"             = @()
            "actionType"                  = $requestBody.actionType
        }
        # Convert the hashtable to a JSON string
        $jsonMessage = $message | ConvertTo-Json
        Write-Output $jsonMessage
        $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
        $StorageAccountKey = Get-Item -Path env:StorageAccountKey
        Write-Output $StorageAccountKey
        $context = New-AzStorageContext -StorageAccountName "staeusavd01" -StorageAccountKey $env:StorageAccountKey
        Write-Output $queueMessage
        $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
        $queue.CloudQueue.AddMessage($queueMessage)
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Message added to the queue."
        }
        
        # Return the response
        $res
    }
    Default {
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Nothing to perform"
        }
        
        # Return the response
        $res
    }
}
# Create the PowerShell object


# Write-Output $message



# $context = New-AzureStorageContext

# # Return a response
# $res = [HttpResponseContext] @{
#     StatusCode = [System.Net.HttpStatusCode]::OK
#     Body       = "Message added to the queue."
# }

# # Return the response
# $res

# # Write to the Azure Functions log stream.
# Write-Host "PowerShell HTTP trigger function processed a request."

# # Interact with query parameters or the body of the request.
# $name = $Request.Query.Name
# if (-not $name) {
#     $name = $Request.Body.Name
# }

# $body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

# if ($name) {
#     $body = "Hello, $name. This HTTP triggered function executed successfully."
# }

# # Associate values to output bindings by calling 'Push-OutputBinding'.
# Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#                                     StatusCode = [HttpStatusCode]::OK
#                                                                          B     ody       = $body
#                                 })
