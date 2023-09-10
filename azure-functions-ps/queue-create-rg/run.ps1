# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
$message = foreach ($key in $QueueItem.Keys) {
    @{ $key = $QueueItem.$Key }
}
$message | ConvertTo-Json -Depth 8
Write-Output $message

# Access and use the hashtable
$resourceGroupName = $message.resourceGroupName
$location = $message.location

# Output some of the values
Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "NIC Name: $location"

Import-Module Az.Resources
#New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
