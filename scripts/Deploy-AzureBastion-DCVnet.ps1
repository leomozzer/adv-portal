### Adding Bastion to vnet-dc
$dcResourceGroupName = "rg-eus-dc-01"
$dcRg = Get-AzResourceGroup -Name $dcResourceGroupName

$dcVnetName = "vnet-eus-dc-01"
$bastionSubnetName = "AzureBastionSubnet"
$dcVnet = Get-AzVirtualNetwork -Name $dcVnetName -ResourceGroupName $dcResourceGroupName
Add-AzVirtualNetworkSubnetConfig `
-Name $bastionSubnetName -VirtualNetwork $dcVnet `
-AddressPrefix "10.0.254.0/24" | Set-AzVirtualNetwork

$publicipName = "pip-eus-dc-01"
New-AzPublicIpAddress -ResourceGroupName $dcResourceGroupName `
-name $publicipName -location $dcRg.Location `
-AllocationMethod Static -Sku Standard

$bastionName = "bastion-eus-dc-01"
New-AzBastion -ResourceGroupName $dcResourceGroupName -Name $bastionName `
-PublicIpAddressRgName $dcResourceGroupName -PublicIpAddressName $publicipName `
-VirtualNetworkRgName $dcResourceGroupName -VirtualNetworkName $dcVnetName `
-Sku "Basic"