$ResourceGroupName = "rg-eus-avd-01"
$VMName = "VM-server-02"
$ScriptPath = "/home/leomozzer/projects/avd/adv-portal/scripts/domainjoin.ps1"  # Local path to the script

Set-AzVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName $VMName `
    -Name "DomainJoinScript" `
    -StorageAccountName "lsoergeusvms081811380" `
    -ContainerName "scripts" `
    -Argument "-ExecutionPolicy Unrestricted" `
    -Run "domainjoin.ps1" `
    -FileName "domainjoin.ps1" `
    -Location "east us"
