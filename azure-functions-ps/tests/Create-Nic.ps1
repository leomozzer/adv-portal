. "../shared/Network-Interface-Card.ps1"
. "../shared/Resource-Group.ps1"

try {
    $createRg = GetResourceGroup -ResourceGroupName "rg-eus-avd-01" -Location "East US"
    Write-Output $createRg
    #CreateNic -Name "1" -ResourceGroupName "rg-eus-avd-01" -Location "East US" -VnetName "vnet-eus-dc-01" -VirtualNetworkResourceGroup "rg-eus-dc-01"
}
catch {
    Write-Output $_.Exception.Message
    if ($_.Exception.Message -eq $false) {
        Write-Output "blaa"
    }
}