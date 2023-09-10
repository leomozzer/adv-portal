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
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
