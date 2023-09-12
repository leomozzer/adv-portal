using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$requestBody = $Request.RawBody | ConvertFrom-Json
$locationShort = If (($requestBody.location -split " ").Count -eq 2) {
    ($requestBody.location -split " ")[0][0] + ($requestBody.location -split " ")[1].Substring(0, 2)
}
Else {
    $requestBody.location.Substring(0, 3)
}

$resourceGroupName = If ($requestBody.resourceGroupName) {
    $requestBody.resourceGroupName
}
Else {
    "rg-$($locationShort.ToLower())-$($requestBody.vmName)"
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

        # Azure Storage Queue setup
        $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
        $context = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
        $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
        $queue.CloudQueue.AddMessage($queueMessage)

        # HTTP response
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Message added to the queue."
        }
    }
    "DomainJoin" {
        $message = @{
            "vmName"                      = $requestBody.vmName
            "location"                    = $requestBody.location
            "resourceGroupName"           = $resourceGroupName
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

        # Azure Storage Queue setup
        $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
        $context = New-AzStorageContext -StorageAccountName "staeusavd01" -StorageAccountKey $env:StorageAccountKey
        $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
        $queue.CloudQueue.AddMessage($queueMessage)

        # HTTP response
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Message added to the queue."
        }
    }
    Default {
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Nothing to perform"
        }
    }
}

# Return the response
$res
