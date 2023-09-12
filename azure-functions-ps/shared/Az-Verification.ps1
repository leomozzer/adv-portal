function CheckResourceGroupExists {
    param (
        [string]$rgName
    )
    if (!(Get-AzResourceGroup -Name $rgName)) {
        return "ResourceGroup $rgName doesn't exist"
    }
    return $rgName
}