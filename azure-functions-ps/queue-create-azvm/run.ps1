# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)
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

    $vmSize = "Standard_B2ms"  # Choose an appropriate VM size
    $adminUsername = "ls0-admin"
    $adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"
    $adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force

    $credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

    $retryCounter = 0
    $nic = Get-AzNetworkInterface -Name "nic-$($getOrder.appName)" -ResourceGroupName "$($getOrder.resourceGroupName)"
    while (!$nic) {
        if ($retryCounter -eq 5) {
            break;
        }
        Write-Host "Retrying to get Nic"
        Start-Sleep 10
        $nic = Get-AzNetworkInterface -Name "nic-$($getOrder.appName)" -ResourceGroupName "$($getOrder.resourceGroupName)"
    }
    $vm = New-AzVMConfig -VMName "vm-$($getOrder.appName)" -VMSize $vmSize
    $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName "vm-$($getOrder.appName)" -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
    $vm = Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName "$($getOrder.resourceGroupName)" -StorageAccountName "staeusavd01"
    $vm = Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-Datacenter' -Version latest

    #New-AzVM -ResourceGroupName "$($getOrder.resourceGroupName)" -Location "$($getOrder.location)" -VM $vm
    $scriptBlock = {
        param ($Vm, $ResourceGroupName, $Location)
        New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $Vm
    }

    Start-Job -ScriptBlock $scriptBlock -ArgumentList @("vm-$($getOrder.appName)", "$($getOrder.resourceGroupName)", $($getOrder.location))

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
