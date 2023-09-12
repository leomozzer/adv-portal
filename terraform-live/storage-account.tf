resource "azurerm_storage_account" "avd_storage_account" {
  name                     = local.avd_storage_account
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.avd_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "domainjoin" {
  name                   = "domainjoin.ps1"
  storage_account_name   = azurerm_storage_account.avd_storage_account.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "../scripts/domainjoin.ps1"
}
