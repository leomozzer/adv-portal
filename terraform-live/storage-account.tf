resource "azurerm_storage_account" "avd-storage-account" {
  name                     = local.avd_storage_account_name
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
