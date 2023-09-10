resource "azurerm_automation_account" "example" {
  name                = "myautomationaccount"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "Basic"
}

data "local_file" "example" {
  filename = "../scripts/domainjoin.ps1"
}

resource "azurerm_automation_runbook" "example" {
  name                    = "JoinDomain"
  resource_group_name     = azurerm_resource_group.resource_group.name
  location                = azurerm_resource_group.resource_group.location
  automation_account_name = azurerm_automation_account.example.name
  runbook_type            = "PowerShell"
  content                 = data.local_file.example.content
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is an example runbook"
}
