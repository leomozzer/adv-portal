using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Import-Module Az.Storage
# Import-Module AzTable

$orderId = [guid]::NewGuid().ToString()
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
        $properties = @{
            "subscriptionId"              = $requestBody.subscriptionId
            "appName"                     = $requestBody.appName
            "actionType"                  = $requestBody.actionType
            "resourceGroupName"           = $resourceGroupName
            "environment"                 = "prod"
            "orderStatus"                 = "Queued"
            "queueOrder"                  = "create-nic,create-azvm,join-domain"
            "ordersCompleted"             = ""
            "location"                    = $requestBody.location
            "virtualNetworkName"          = $requestBody.virtualNetworkName
            "subnetName"                  = $requestBody.subnetName
            "virtualNetworkResourceGroup" = $requestBody.virtualNetworkResourceGroup
        }

        AddTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
            -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
            -tableName "orders" `
            -partionKey $requestBody.actionType `
            -rowKey $orderId `
            -properties $properties

        AddMessage -storageAccountName $env:STORAGE_ACCOUNT_NAME `
            -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
            -queueName ($getOrder.queueOrder -split ",")[0] `
            -message $orderId
        # $message = @{
        #     "subscriptionId"              = $requestBody.subscriptionId
        #     "appName"                     = $requestBody.appName
        #     "location"                    = $requestBody.location
        #     "resourceGroupName"           = $resourceGroupName
        #     "virtualNetworkResourceGroup" = $requestBody.virtualNetworkResourceGroup
        #     "virtualNetworkName"          = $requestBody.virtualNetworkName
        #     "subnetName"                  = $requestBody.subnetName
        #     "nicName"                     = "nic-$($requestBody.appName)"
        #     "queueOrder"                  = @("create-nic", "create-azvm", "join-domain")
        #     "ordersCompleted"             = @()
        #     "actionType"                  = $requestBody.actionType
        # }

        # Convert the hashtable to a JSON string
        # $jsonMessage = $message | ConvertTo-Json

        # # Azure Storage Queue setup
        # $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
        # $context = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
        # $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
        # $table = Get-AzStorageTable -Name $env:STORAGE_ACCOUNT_ORDERS_TABLE -Context $context

        # Add-AzTableRow -Table "$($table.CloudTable)" -PartitionKey $requestBody.actionType -RowKey $orderId -property
        # $queue.CloudQueue.AddMessage($queueMessage)

        # HTTP response
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Message added to the queue $(($properties.queueOrder -split ",")[0])"
        }
    }
    # "DomainJoin" {
    #     $message = @{
    #         "subscriptionId"              = $requestBody.subscriptionId
    #         "appName"                     = $requestBody.appName
    #         "location"                    = $requestBody.location
    #         "resourceGroupName"           = $resourceGroupName
    #         "virtualNetworkResourceGroup" = $requestBody.virtualNetworkResourceGroup
    #         "virtualNetworkName"          = $requestBody.virtualNetworkName
    #         "subnetName"                  = $requestBody.subnetName
    #         "nicName"                     = "nic-$($requestBody.appName)"
    #         "queueOrder"                  = @("create-rg", "create-nic", "create-azvm", "join-domain")
    #         "ordersCompleted"             = @()
    #         "actionType"                  = $requestBody.actionType
    #     }

    #     # Convert the hashtable to a JSON string
    #     $jsonMessage = $message | ConvertTo-Json

    #     # Azure Storage Queue setup
    #     $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($jsonMessage)
    #     $context = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
    #     $queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
    #     $queue.CloudQueue.AddMessage($queueMessage)

    #     # HTTP response
    #     $res = [HttpResponseContext] @{
    #         StatusCode = [System.Net.HttpStatusCode]::OK
    #         Body       = "Message added to the queue $($message.queueOrder[0])"
    #     }
    # }
    Default {
        $res = [HttpResponseContext] @{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = "Nothing to perform"
        }
    }
}

# Return the response
$res
