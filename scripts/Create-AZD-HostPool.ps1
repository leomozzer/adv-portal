#Vnet must exists before the creation of the VM
#lso-admin
#j68muqT19hBkYHAJM6Z!0nv#FDqS

$resourceGroupName = "rg-eus-avd-01"
$location = "East US"

New-AzResourceGroup -Name $resourceGroupName -Location $location

$vnetName = "vnet-eus-avd-01"
$subnetName = "snet-desktop"

#Vnet from the avd 
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -Location $location -AddressPrefix "10.1.0.0/16"
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix "10.1.0.0/24"

$array = @("10.0.0.4", "10.0.0.5")
$newObject = New-Object -type PSObject -Property @{"DnsServers" = $array }
$vnet.DhcpOptions = $newObject
$vnet | Set-AzVirtualNetwork

#Creating the peering with the aadds-vnet to the vnet-eus-avd-01

$dcVnet = Get-AzVirtualNetwork -Name "vnet-eus-dc-01" -ResourceGroupName "rg-eus-dc-01"

Add-AzVirtualNetworkPeering `
    -Name "vnet-eus-dc-01-to-vnet-eus-avd-01" `
    -VirtualNetwork $vnet `
    -RemoteVirtualNetworkId $dcVnet.Id

Add-AzVirtualNetworkPeering `
    -Name "vnet-eus-dc-01-to-vnet-eus-avd-01" `
    -VirtualNetwork $dcVnet `
    -RemoteVirtualNetworkId $vnet.Id


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



$bastionName = "bastion-eus-avd-01"
$publicIpAddressName = "pip-$bastionName"
New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -name $publicIpAddressName -location $location -AllocationMethod Static -Sku Standard

New-AzBastion -ResourceGroupName $resourceGroupName -Name $bastionName -PublicIpAddressName $publicIpAddressName -VirtualNetworkName $vnetName -PublicIpAddressRgName $resourceGroupName -VirtualNetworkRgName $resourceGroupName

$parameters = @{
    Name                          = 'hostpool-eus-avd-01'
    ResourceGroupName             = 'rg-eus-avd-01'
    HostPoolType                  = 'Personal'
    LoadBalancerType              = 'Persistent'
    PreferredAppGroupType         = 'Desktop'
    PersonalDesktopAssignmentType = 'Automatic'
    Location                      = 'East US'
    CustomRdpProperty             = "targetisaadjoined:i:1"
    ValidationEnvironment         = $true
}
#https://learn.microsoft.com/en-us/powershell/module/az.desktopvirtualization/new-azwvdhostpool?view=azps-10.1.0

#Took 10 minutes to create it
New-AzWvdHostPool @parameters

Get-AzWvdHostPool -Name $parameters.Name -ResourceGroupName $resourceGroupName

#Create registration token for Hostpool
$GetToken = New-AzWvdRegistrationInfo -ResourceGroupName $resourceGroupName -HostPoolName $parameters.Name -ExpirationTime (Get-Date).AddDays(14) -ErrorAction SilentlyContinue


$hostPoolArmPath = (Get-AzWvdHostPool -Name $parameters.Name -ResourceGroupName $resourceGroupName).Id

$appGroupParameters = @{
    Name                 = 'appgroup-eus-avd-01'
    ResourceGroupName    = $resourceGroupName
    ApplicationGroupType = 'Desktop'
    HostPoolArmPath      = $hostPoolArmPath
    Location             = $parameters.Location
}
#Create Application Group
New-AzWvdApplicationGroup @appGroupParameters

$appGroupId = (Get-AzWvdApplicationGroup -Name $appGroupParameters.Name -ResourceGroupName $resourceGroupName).Id

#Create Workspace
New-AzWvdWorkspace -Name 'ws-eus-avd-01' -ResourceGroupName $resourceGroupName -Location $parameters.Location -ApplicationGroupReference $appGroupId

##Part that must be perforemed over azure function

# Create Windows Server 2019
$vmName = "vm-dc-02"
$vmSize = "Standard_B2ms"  # Choose an appropriate VM size
$adminUsername = "ls0-admin"
$adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"

$adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

$nicName = "nic-$vmName"

$subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.Subnets[0].id

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-Datacenter' -Version latest

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

# $VMName = "YourVMName"
# $DeviceName = "YourDeviceName"

# Add-AzureADDeviceMember -ObjectId $vmName -RefObjectId $vmName

#opitional
# $publicIpAddressName = "pip-$vmName"
# $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
# $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
# $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName
# $pip = Get-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName
# $nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PublicIPAddress $pip -Subnet $subnet
# $nic | Set-AzNetworkInterface

# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion = "1.0"

Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName


# AVD Azure AD Join domain extension
$moduleLocation = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_01-19-2023.zip"
$avdExtensionName = "DSC"
$avdExtensionPublisher = "Microsoft.Powershell"
$avdExtensionVersion = "2.73"
$avdExtensionSetting = @{
    modulesUrl            = $moduleLocation
    ConfigurationFunction = "Configuration.ps1\AddSessionHost"
    Properties            = @{
        HostPoolName          = "hostpool-eus-avd-0"
        registrationInfoToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ4Q0Y2MjhENTM5OUYzNTMwQkM5MzI0RjgyMzVFNEY1RkEyOTQxNkIiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjAxNjk3ZTYzLWYzZDEtNDExZC05NDRhLWQxODFkNTgwZmQ5NiIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiY2U5NzM2ZDItYjQ3YS00ZDkxLWJiYjYtOTM1ZTQ5MTdjNWE4IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL2NlOTczNmQyLWI0N2EtNGQ5MS1iYmI2LTkzNWU0OTE3YzVhOC5yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJCcm9rZXJSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly9jZTk3MzZkMi1iNDdhLTRkOTEtYmJiNi05MzVlNDkxN2M1YTgucmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1Jlc291cmNlSWRVcmkiOiJodHRwczovL2NlOTczNmQyLWI0N2EtNGQ5MS1iYmI2LTkzNWU0OTE3YzVhOC5yZGRpYWdub3N0aWNzLWctdXMtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwiQUFEVGVuYW50SWQiOiIwMzgwM2UyYi1kODMwLTQ5YjAtODFkMS1lMzhjYjc5NmJkYjIiLCJuYmYiOjE2OTIzMTQyODMsImV4cCI6MTY5MjQwMDY2OCwiaXNzIjoiUkRJbmZyYVRva2VuTWFuYWdlciIsImF1ZCI6IlJEbWkifQ.MBvj8-bJ1LGctavQQtoYJvhKVxhGAEKNWGm0g6wOrG_FnIux9QUQvq7OCmLcNIHLteIi64QLbQfpHnN4B8pbFtzBKs4bb07Ql_HuPm2q2Cxk1AjL9ZPrWzeRDQLqB-o5YwraZxlC5UShI_toQ0ZwGeZwRcrlxpvacA-gyu4NQFY5z-UsApTcAQ14AhSelQgZz-hWlkEpP5ScqKBvJJMLze0K1iVXAKDWtN6ck5gk9EhCAElO686sdsBbqy3ItV6-SUxuCjre5yYmK3S08F3eDCJjWzuayqTbPME5MFZKWaZ2jGbsk7q5ppcCtTPV7ATyNqFFZ3NDbYoQwnnSz-L6GA"
        aadJoin               = $true
    }
}
Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $avdExtensionVersion -Publisher $avdExtensionPublisher -ExtensionType $avdExtensionName -Name $avdExtensionName -Settings $avdExtensionSetting

#Create Windows 10 VM
$vmName = "VM-01"
$vmSize = "Standard_DS2_v2"  # Choose an appropriate VM size
$adminUsername = "ls0-admin"
$adminPassword = "j68muqT19hBkYHAJM6Z!0nv#FDqS"

$adminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminSecurePassword)

$nicName = "nic-vm-01"

$subnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.Subnets[0].id

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id
$vm = Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-10' -Skus '20h2-evd' -Version latest

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

# $VMName = "YourVMName"
# $DeviceName = "YourDeviceName"

# Add-AzureADDeviceMember -ObjectId $vmName -RefObjectId $vmName

#opitional
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName
$pip = Get-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName
$nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PublicIPAddress $pip -Subnet $subnet
$nic | Set-AzNetworkInterface

# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion = "1.0"

Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName


# AVD Azure AD Join domain extension
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
Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $avdExtensionVersion -Publisher $avdExtensionPublisher -ExtensionType $avdExtensionName -Name $avdExtensionName -Settings $avdExtensionSetting














#Join VM to domain
# Set your Azure AD credentials
$AzureADUsername = ""
$AzureADPassword = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AzureADUsername, $AzureADPassword)

# Join Azure AD
Add-AzureADDevice -DisplayName $vmName -DeviceId $vmName -DeviceName $vmName -UserPrincipalName $AzureADUsername -DeviceOSType "Windows" -DeviceOSVersion "10.0" -DeviceTrustType "DomainJoin" -RegisteredOwners $AzureADUsername -Credential $Credential



$ResourceGroupName = "YourResourceGroupName"
$VmName = "YourVMName"
$ScriptUri = "https://yourstorage.blob.core.windows.net/scripts/join-azure-ad.ps1"

Set-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VmName -Location "East US" -Name "join-azure-ad" -Type "CustomScriptExtension" -Publisher "Microsoft.Compute" -TypeHandlerVersion 1.10 -SettingString '{"scriptUri":"$ScriptUri"}'



# Install-Module AzureAD
# Install-Module AzureRm
# Connect-AzureAD

# $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
# $extensionName = "joindomain"
# $extensionPublisher = "Microsoft.Compute"
# $extensionType = "JsonADDomainExtension"

# $settings = @{
#     "Name" = "YourDomainName"
#     "OUPath" = "OU=YourOU,DC=YourDomain,DC=com"
#     "OUExists" = "false"
#     "User" = "YourAdminUsername"
#     "Restart" = "true"
# }

# $protectedSettings = @{
#     "Password" = "YourAdminPassword"
# }

# $extensionParams = @{
#     "VMName" = $vmName
#     "ResourceGroupName" = $resourceGroupName
#     "Location" = $vm.Location
#     "ExtensionName" = $extensionName
#     "Publisher" = $extensionPublisher
#     "ExtensionType" = $extensionType
#     "TypeHandlerVersion" = "1.3"
#     "Settings" = $settings
#     "ProtectedSettings" = $protectedSettings
# }

# Set-AzVMExtension @extensionParams

#Atach VM to pool
$vmResourceId = (Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName).Id
$app = Get-AzWvdApplicationGroup -Name $appGroupParameters.Name -ResourceGroupName $resourceGroupName
Update-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $parameters.Name -SessionHostName $vmName