$adminRegEntry = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
Set-ItemProperty -Path $AdminRegEntry -Name 'IsInstalled' -Value 0
Stop-Process -Name Explorer

$dc = "lab"
$adminUser = "admin"
New-ADOrganizationalUnit 'AzureADConnect' -path "DC=$dc,DC=com" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit 'AVDClients' -path "DC=$dc,DC=com" -ProtectedFromAccidentalDeletion $false

$ouName = 'AzureADConnect'
$ouPath = "OU=$ouName,DC=$dc,DC=com"
$adUserNamePrefix = 'aduser'
$adUPNSuffix = "$dc.com"
$userCount = 1..9
foreach ($counter in $userCount) {
    New-AdUser -Name $adUserNamePrefix$counter -Path $ouPath -Enabled $True `
        -ChangePasswordAtLogon $false -userPrincipalName $adUserNamePrefix$counter@$adUPNSuffix `
        -AccountPassword (ConvertTo-SecureString 'Pass@word1' -AsPlainText -Force) -passThru
} 

$adUserNamePrefix = 'avdadmin1'
$adUPNSuffix = "$dc.com"
New-AdUser -Name $adUserNamePrefix -Path $ouPath -Enabled $True `
    -ChangePasswordAtLogon $false -userPrincipalName $adUserNamePrefix@$adUPNSuffix `
    -AccountPassword (ConvertTo-SecureString 'Pass@word1' -AsPlainText -Force) -passThru

Get-ADGroup -Identity 'Domain Admins' | Add-AdGroupMember -Members $$adUserNamePrefix

New-ADGroup -Name "$dc-avd-pooled" -GroupScope 'Global' -GroupCategory Security -Path $ouPath
New-ADGroup -Name "$dc-avd-remote-app" -GroupScope 'Global' -GroupCategory Security -Path $ouPath
New-ADGroup -Name "$dc-avd-personal" -GroupScope 'Global' -GroupCategory Security -Path $ouPath
New-ADGroup -Name "$dc-avd-users" -GroupScope 'Global' -GroupCategory Security -Path $ouPath
New-ADGroup -Name "$dc-avd-admins" -GroupScope 'Global' -GroupCategory Security -Path $ouPath

Get-ADGroup -Identity "$dc-avd-pooled" | Add-AdGroupMember -Members 'aduser1', 'aduser2', 'aduser3', 'aduser4'
Get-ADGroup -Identity "$dc-avd-remote-app" | Add-AdGroupMember -Members 'aduser1', 'aduser5', 'aduser6'
Get-ADGroup -Identity "$dc-avd-personal" | Add-AdGroupMember -Members 'aduser7', 'aduser8', 'aduser9'
Get-ADGroup -Identity "$dc-avd-users" | Add-AdGroupMember -Members 'aduser1', 'aduser2', 'aduser3', 'aduser4', 'aduser5', 'aduser6', 'aduser7', 'aduser8', 'aduser9'
Get-ADGroup -Identity "$dc-avd-admins" | Add-AdGroupMember -Members $adUserNamePrefix

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force -SkipPublisherCheck

Install-Module -Name Az -AllowClobber -SkipPublisherCheck

Connect-AzAccount

$tenantId = (Get-AzContext).Tenant.Id

Install-Module -Name AzureAD -Force
Import-Module -Name AzureAD

Connect-AzureAD -TenantId $tenantId

$aadDomainName = ((Get-AzureAdTenantDetail).VerifiedDomains)[0].Name

Get-ADForest | Set-ADForest -UPNSuffixes @{add = "$aadDomainName" }

$domainUsers = Get-ADUser -Filter { UserPrincipalName -like "*$dc.com" } -Properties userPrincipalName -ResultSetSize $null
$domainUsers | foreach { $newUpn = $_.UserPrincipalName.Replace("$dc.com", $aadDomainName); $_ | Set-ADUser -UserPrincipalName $newUpn }

$domainAdminUser = Get-ADUser -Filter { sAMAccountName -eq $adminUser } -Properties userPrincipalName
$domainAdminUser | Set-ADUser -UserPrincipalName "$adminUser@$dc.com"

$userName = 'aadsyncuser'
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = 'Pass@word1'
$passwordProfile.ForceChangePasswordNextLogin = $false
New-AzureADUser -AccountEnabled $true -DisplayName $userName -PasswordProfile $passwordProfile -MailNickName $userName -UserPrincipalName "$userName@$aadDomainName"

$aadUser = Get-AzureADUser -ObjectId "$userName@$aadDomainName"
$aadRole = Get-AzureADDirectoryRole | Where-Object { $_.displayName -eq 'Global administrator' } 
Add-AzureADDirectoryRoleMember -ObjectId $aadRole.ObjectId -RefObjectId $aadUser.ObjectId

(Get-AzureADUser -Filter "MailNickName eq '$userName'").UserPrincipalName

New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SystemDefaultTlsVersions' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -name 'SchUseStrongCrypto' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'Enabled' -value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
Write-Host 'TLS 1.2 has been enabled.'


New-ADOrganizationalUnit 'AVDInfra' –path "DC=$dc,DC=com" -ProtectedFromAccidentalDeletion $false