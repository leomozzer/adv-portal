# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"

Import-Module Az.Accounts
Import-Module Az.Network
Import-Module Az.Storage
Import-Module Az.Compute

$message = foreach ($key in $QueueItem.Keys) {
    @{ $key = $QueueItem.$Key }
}
$message | ConvertTo-Json -Depth 8
Write-Output $message

# Access and use the hashtable
$resourceGroupName = $message.resourceGroupName
$location = $message.location
$nicName = $message.nicName
$subscriptionId = $message.subscriptionId
$vmName = $message.appName

$vmSize = "Standard_B2ms"  # Choose an appropriate VM size
$adminUsername = "ls0-admin"
$adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"

$adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

# Output some of the values
Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "NIC Name: $location"
Set-AzContext -Subscription $subscriptionId

$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName $resourceGroupName -StorageAccountName "staeusavd01"
$vm = Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
