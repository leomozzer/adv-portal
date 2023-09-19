$properties = @{
    "subscriptionId"  = $requestBody.subscriptionId
    "appName"         = $requestBody.appName
    "actionType"      = $requestBody.actionType
    "environment"     = "prod"
    "orderStatus"     = "Queued"
    "queueOrder"      = "create-nic,create-azvm,join-domain"
    "ordersCompleted" = ""
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

$getOrder = GetTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -tableName "orders" `
    -columnName "RowKey" `
    -value $QueueItem `
    -operator "Equal"


CreateNic -Name "$($getOrder.appName)" -ResourceGroupName "$($getOrder.resourceGroupName)" -Location "$($getOrder.location)" -VnetName "$($getOrder.vnetName)" -VirtualNetworkResourceGroup "$($getOrder.virtualNetworkResourceGroup)"
$getOrder.orderStatus = "Processing"
$getOrder.ordersCompleted += If (($getOrder.ordersCompleted.Length -gt 0)) {
    ",$(($getOrder.queueOrder -split ",")[0])"
}
else {
    ($getOrder.queueOrder -split ",")[0]
}
$getOrder.queueOrder = ($getOrder.queueOrder -split "," | Select-Object -Skip 1) -join ","

UpdateTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -tableName "orders" `
    -item $getOrder

AddMessage -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -queueName ($getOrder.queueOrder -split ",")[0] `
    -message $orderId