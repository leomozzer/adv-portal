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
        $context = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
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
    
        return $res
    }
}
