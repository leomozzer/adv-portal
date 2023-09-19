function GetResourceGroup {
    param (
        [Parameter(Mandatory = $true)] [string] $ResourceGroupName,
        [Parameter(Mandatory = $true)] [string] $Location
    )
    if ((Get-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location)) {
        return $true
    }
    else {
        return $false
    }
}