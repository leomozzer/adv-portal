# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
$message = foreach ($key in $QueueItem.Keys) {
    @{ $key = $QueueItem.$Key }
}
$message | ConvertTo-Json -Depth 8
Write-Output $message
$message | ConvertTo-Json -Depth 8
Write-Output $message

# Access and use the hashtable
$resourceGroupName = $message.resourceGroupName
$virtualNetworkResourceGroup = $message.virtualNetworkResourceGroup
$location = $message.location
$vnetName = $message.virtualNetworkName
$nicName = $message.nicName

# Output some of the values
Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "NIC Name: $location"

Import-Module Az.Accounts

$subscription = ""
# $identity = "c71e4150-de9c-4722-a4d2-e44bb3bbd29d"
# null = Disable-AzContextAutosave -Scope Process # Ensures you do not inherit an AzContext in your runbook
# $AzureContext = (Connect-AzAccount -Identity).context 
Set-AzContext -Subscription $subscription

Import-Module Az.Network
$subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $virtualNetworkResourceGroup
New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.Subnets[0].id

$completedAction = $message.queueOrder[0]
$message.queueOrder = $message.queueOrder | Select-Object -Skip 1

# Add the removed item to the ordersCompleted array
$message.ordersCompleted += $completedAction

$queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($message)
$context = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
Write-Output $queueMessage
$queue = Get-AzStorageQueue -Name $message.queueOrder[0] -Context $context
$queue.CloudQueue.AddMessage($queueMessage)
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
