# Credentials for Azure AD join
$AzureADUsername = ""
$AzureADPassword = "" | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AzureADUsername, $AzureADPassword)

# Join the VM to Azure AD
Add-Computer -DomainName "" -Credential $Credential -Restart

# Optionally, specify an Organizational Unit (OU) for the computer account
$OUPath = "OU=AVD Computers,DC=,DC=onmicrosoft,DC=com"
Add-Computer -DomainName "" -Credential $Credential -OUPath $OUPath -Restart

# Notify completion
Write-Host "Azure AD join completed."