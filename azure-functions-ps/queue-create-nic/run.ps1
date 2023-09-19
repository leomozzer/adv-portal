# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"

try {
    $getOrder = GetTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
        -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
        -tableName "orders" `
        -columnName "RowKey" `
        -value $QueueItem `
        -operator "Equal"

    Write-Output $getOrder

    Set-AzContext -Subscription "$($getOrder.subscriptionId)"

    CreateNic -Name "$($getOrder.appName)" -ResourceGroupName "$($getOrder.resourceGroupName)" -Location "$($getOrder.location)" -VnetName "$($getOrder.virtualNetworkName)" -VirtualNetworkResourceGroup "$($getOrder.virtualNetworkResourceGroup)"

    $getOrder.orderStatus = "Processing"
    $getOrder.ordersCompleted += If (($getOrder.ordersCompleted.Length -gt 0)) {
        ",$(($getOrder.queueOrder -split ",")[0])"
    }
    else {
        ($getOrder.queueOrder -split ",")[0]
    }
    $getOrder.queueOrder = ($getOrder.queueOrder -split "," | Select-Object -Skip 1) -join ","

    # To commit the change, pipe the updated record into the update cmdlet.
    $Ctx = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME  -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
          
    $Table = (Get-AzStorageTable -Name "orders" -Context $ctx).CloudTable  
    $getOrder | Update-AzTableRow -table $Table

    AddMessage -storageAccountName $env:STORAGE_ACCOUNT_NAME `
        -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
        -queueName ($getOrder.queueOrder -split ",")[0] `
        -message $getOrder.RowKey
}
catch {
    Write-Host $_.Exception.Message
}

Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
