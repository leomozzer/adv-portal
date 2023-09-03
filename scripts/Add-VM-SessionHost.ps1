[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]
    $VmResourceGroup = "rg-eus-avd-01",
    [Parameter(Mandatory = $false)]
    [string]
    $VmName = "VM-01",
    [Parameter(Mandatory = $false)]
    [string]
    $VmLocation = "East Us",
    [Parameter(Mandatory = $false)]
    [string]
    $VmSize = "Standard_B2ms",
    [Parameter(Mandatory = $false)]
    [string]
    $VmPublisherName = "MicrosoftWindowsDesktop",
    [Parameter(Mandatory = $false)]
    [string]
    $VmOffer = "Windows-10",
    [Parameter(Mandatory = $false)]
    [string]
    $VmSku = "20h2-evd",
    [Parameter(Mandatory = $false)]
    [string]
    $VmVersion = "latest",
    [Parameter(Mandatory = $false)]
    [string]
    $VnetName = "vnet-eus-dc-01",
    [Parameter(Mandatory = $false)]
    [string]
    $HostPoolName = "hostpool-eus-avd-01",
    [Parameter(Mandatory = $false)]
    [string]
    $AvdResourceGroup = "rg-eus-avd-01"
)

$GetToken = Get-AzWvdHostPoolRegistrationToken -ResourceGroupName $AvdResourceGroup -HostPoolName $HostPoolName

Write-Output $GetToken

$moduleLocation = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_01-19-2023.zip"
$avdExtensionName = "DSC"
$avdExtensionPublisher = "Microsoft.Powershell"
$avdExtensionVersion = "2.73"
$avdExtensionSetting = @{
    modulesUrl            = $moduleLocation
    ConfigurationFunction = "Configuration.ps1\AddSessionHost"
    Properties            = @{
        HostPoolName          = $hostpoolName
        registrationInfoToken = $($GetToken.Token)
        aadJoin               = $true
    }
}
Set-AzVMExtension -VMName $vmName `
    -ResourceGroupName $VmResourceGroup `
    -Location $VmLocation `
    -TypeHandlerVersion $avdExtensionVersion `
    -Publisher $avdExtensionPublisher `
    -ExtensionType $avdExtensionName `
    -Name $avdExtensionName `
    -Settings $avdExtensionSetting