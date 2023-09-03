$ResourceGroupName = "rg-eus-avd-01"
$VMName = "VM-01"
$ScriptURI = "https://imagineafancynamehere.blob.core.windows.net/scripts/domainjoin.ps1"

Set-AzVMCustomScriptExtension -ResourceGroupName "rg-eus-avd-01" `
    -Location "East US" `
    -VMName $vmName `
    -Name "JoinDomainScript" `
    -TypeHandlerVersion "1.1" `
    -StorageAccountName "lsoergeusvm0090316050" `
    -FileName "domainjoin.ps1" `
    -ContainerName "scripts" `

# Set-AzVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
#     -VMName $VMName `
#     -Name "JoinDomainScript" `
#     -ScriptURI "https://imagineafancynamehere.blob.core.windows.net/scripts/domainjoin.ps1" `
#     -Run "domainjoin.ps1"
# # -Argument "-DomainName yourdomain.com -DomainUser domainadmin -DomainPassword YourPassword -OUPath 'OU=Computers,DC=yourdomain,DC=com'"