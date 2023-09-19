$ErrorActionPreference = 'SilentlyContinue'
function CreateNic {
    param (
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $Location,
        [Parameter(Mandatory = $true)] [string] $VnetName,
        [Parameter(Mandatory = $true)] [string] $VirtualNetworkResourceGroup
    )
    try {
        $nicName = "nic-$Name"
        if (!(Get-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroupName)) {
            $subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $virtualNetworkResourceGroup
            New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.Subnets[0].id
        }
        else {
            throw "Network Interface Card $nicName already exists"
        }
    }
    catch {
        Write-Host $_.Exception.Message
    }
}