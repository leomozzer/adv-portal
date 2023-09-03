# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmName = "VM-01",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmLocation = "East Us",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmSize = "Standard_DS2_v2",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmPublisherName = "MicrosoftWindowsDesktop",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmOffer = "Windows-10",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmSku = "20h2-evd",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VmVersion = "latest",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VnetName = "vnet-eus-dc-01",
#     [Parameter(Mandatory = $false)]
#     [string]
#     $VnetResourceGroup = "rg-eus-dc-01"
# )

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [object] $WebhookData
)

if ($WebhookData.RequestBody) { 
    $body = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    $VmName = $body.vmname
    $VmLocation = $body.location
    $VmSize = $body.vmzise
    $VmPublisherName = $body.publishername
    $VmOffer = $body.vmoffer
    $VmSku = $body.sku
    $VmVersion = $body.vmversion
    $VnetName = $body.vnetname
    $VnetResourceGroup = $body.vnetrg
    $VmResourceGroup = "rg-eus-avd-$VmName"
}
else {
    Write-Output "Hello World!"
}

# $VmName = "VM-01"
# $VmLocation = "East Us"
# $VmSize = "Standard_DS2_v2"
# $VmPublisherName = "MicrosoftWindowsDesktop"
# $VmOffer = "Windows-10"
# $VmSku = "20h2-evd"
# $VmVersion = "latest"
# $VnetName = "vnet-eus-dc-01"
# $VnetResourceGroup = "rg-eus-dc-01"

# $VmResourceGroup = "rg-eus-avd-$VmName"



New-AzResourceGroup -Name $VmResourceGroup -Location $VmLocation

#Create Windows 10 VM
#$vmName = "VM-01"
#$vmSize = "Standard_DS2_v2"  # Choose an appropriate VM size
#Need to transform this in a ramdom param
$adminUsername = "ls0-admin"
$adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"

$adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

$nicName = "nic-$VmName"

$subnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $VnetResourceGroup
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $VmResourceGroup -Location $VmLocation -SubnetId $subnet.Subnets[0].id

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMSourceImage -VM $vm -PublisherName $VmPublisherName -Offer $VmOffer -Skus $VmSku -Version $VmVersion

New-AzVM -ResourceGroupName $VmResourceGroup -Location $VmLocation -VM $vm