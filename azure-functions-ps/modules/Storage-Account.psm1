function AddTableRow {
    param (
        [string] $storageAccountName,
        [string] $storageAccountKey,
        [string] $tableName,
        [string] $partionKey,
        [string] $rowKey,
        [object] $properties
    )
    Try {
        $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $cloudTable = (Get-AzStorageTable -Name $tableName -Context $context).CloudTable
        Add-AzTableRow -Table $cloudTable -PartitionKey $partionKey -RowKey $rowKey -property $properties
        Write-Host "New item was added to table '$tableName'"   
    }
    Catch {
        Write-Host "Failed to AddTableRow"
        Write-Host $_.Exception.Message
    }
}

function GetTableRow {
    param (
        [string] $storageAccountName,
        [string] $storageAccountKey,
        [string] $tableName,
        [string] $columnName,
        [string] $value,
        [string] $operator
    )
    Try {
        $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $cloudTable = (Get-AzStorageTable -Name $tableName -Context $context).CloudTable
        $item = Get-AzTableRow -table $cloudTable `
            -columnName $columnName `
            -value $value `
            -operator $operator
        return $item
    }
    Catch {
        Write-Host "Failed to GetTableRow"
        Write-Host $_.Exception.Message
    }
}

function UpdateTableRow {
    param (
        [string] $storageAccountName,
        [string] $storageAccountKey,
        [string] $tableName,
        $item
    )
    Write-Output $item
    Try {
        $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $cloudTable = (Get-AzStorageTable -Name $tableName -Context $context).CloudTable
        $item | Update-AzTableRow -table $cloudTable
    }
    Catch {
        Write-Host "Failed to UpdateTableRow"
        Write-Host $_.Exception.Message
    }
}

function AddMessage {
    param (
        [string] $storageAccountName,
        [string] $storageAccountKey,
        [string] $queueName,
        [string] $message
    )
    Try {
        $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $queue = Get-AzStorageQueue -Name $queueName -Context $context
        $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($message)
        $queue.CloudQueue.AddMessage($queueMessage)
        Write-Host "Message '$message' was added into the queue $queueName"
    }
    Catch {
        Write-Host "Failed to AddMessage"
        Write-Host $_.Exception.Message
    }
}