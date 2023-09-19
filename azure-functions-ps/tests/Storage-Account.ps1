#. "../shared/Storage-Account.ps1"

Import-Module "../shared/Storage-Account.psm1"

$orderId = [guid]::NewGuid().ToString()

$properties = @{
    "subscriptionId"  = $([guid]::NewGuid().ToString())
    "appName"         = (Get-Date -Format "HHmmMMddyyyy")
    "actionType"      = "CreateRg"
    "environment"     = "prod"
    "orderStatus"     = "Queued"
    "queueOrder"      = "create-rg"
    "ordersCompleted" = ""
}
    
AddTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -tableName "orders" `
    -partionKey $properties.actionType `
    -rowKey $orderId `
    -properties $properties

    
AddMessage -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -queueName ($getOrder.queueOrder -split ",")[0] `
    -message $orderId

Start-Sleep 5

$getOrder = GetTableRow -storageAccountName $env:STORAGE_ACCOUNT_NAME `
    -storageAccountKey $env:STORAGE_ACCOUNT_KEY `
    -tableName "orders" `
    -columnName "RowKey" `
    -value $orderId `
    -operator "Equal"


#$getOrder = $getOrder | ConvertTo-Json -Depth 8
Write-Host $getOrder

$getOrder.orderStatus = "Processing"

$getOrder.ordersCompleted += If (($getOrder.ordersCompleted.Length -gt 0)) {
    ",$(($getOrder.queueOrder -split ",")[0])"
}
else {
        ($getOrder.queueOrder -split ",")[0]
}
$getOrder.queueOrder = ($getOrder.queueOrder -split "," | Select-Object -Skip 1) -join ","

Write-Host $getOrder
# To commit the change, pipe the updated record into the update cmdlet.
$Ctx = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME  -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
  
$Table = (Get-AzStorageTable -Name "orders" -Context $ctx).CloudTable  
$getOrder | Update-AzTableRow -table $Table

# $StorageAccountName = $env:STORAGE_ACCOUNT_NAME
  
# $Ctx = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME  -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
  
# $Table = (Get-AzStorageTable -Name "orders" -Context $ctx).CloudTable  

# Write-Host $Table
  
# Add-AzTableRow -Table $Table -PartitionKey "PK1" -RowKey "RK12" -property @{"Name" = "John"; "LastName" = "Doe" }

# Start-Sleep 10
# $Ctx = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME  -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
  
# $Table = (Get-AzStorageTable -Name "orders" -Context $ctx).CloudTable  
# $user = Get-AzTableRow -table $Table `
#     -columnName "Name" `
#     -value "John" `
#     -operator Equal

# $user.Name = "Jessie2"

# Start-Sleep 10

# # To commit the change, pipe the updated record into the update cmdlet.
# $Ctx = New-AzStorageContext -StorageAccountName $env:STORAGE_ACCOUNT_NAME  -StorageAccountKey $env:STORAGE_ACCOUNT_KEY
  
# $Table = (Get-AzStorageTable -Name "orders" -Context $ctx).CloudTable  
# Write-Host $user
# $user | Update-AzTableRow -table $Table

