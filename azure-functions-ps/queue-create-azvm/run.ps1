# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
$message | ConvertTo-Json -Depth 8
Write-Output $message

# Access and use the hashtable
$resourceGroupName = $message.resourceGroupName
$location = $message.location
$vnetName = $message.virtualNetworkName
$nicName = $message.nicName

$vmSize = "Standard_B2ms"  # Choose an appropriate VM size
$adminUsername = "ls0-admin"
$adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"

$adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

# Output some of the values
Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "NIC Name: $location"
$subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.Subnets[0].id

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
