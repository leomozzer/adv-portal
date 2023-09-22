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

    Set-AzVMCustomScriptExtension -ResourceGroupName "$($getOrder.resourceGroupName)" `
        -Location "$($getOrder.location)" `
        -VMName "vm-$($getOrder.appName)" `
        -Name "JoinDomainScript" `
        -TypeHandlerVersion "1.1" `
        -StorageAccountName "staeusavd01" `
        -FileName "domainjoin.ps1" `
        -ContainerName "scripts"
}
catch {
    Write-Host $_.Exception.Message
}
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
