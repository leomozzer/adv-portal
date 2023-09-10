resource "azurerm_resource_group" "resource_group_portal" {
  name     = local.resource_group_name_portal
  location = var.location
  tags = {
    "Environment" : var.environment
  }
}

resource "azurerm_storage_account" "avd-storage-account-portal" {
  name                     = local.avd_storage_account_name
  location                 = azurerm_resource_group.resource_group_portal.location
  resource_group_name      = azurerm_resource_group.resource_group_portal.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "queue" {
  for_each             = toset(var.queue_list)
  name                 = each.value
  storage_account_name = azurerm_storage_account.avd-storage-account-portal.name
}

resource "azurerm_service_plan" "func_app" {
  name                = local.service_plan_portal
  resource_group_name = azurerm_resource_group.resource_group_portal.name
  location            = azurerm_resource_group.resource_group_portal.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "func_app_portal" {
  name                = local.function_app
  resource_group_name = azurerm_resource_group.resource_group_portal.name
  location            = azurerm_resource_group.resource_group_portal.location

  storage_account_name       = azurerm_storage_account.avd-storage-account-portal.name
  storage_account_access_key = azurerm_storage_account.avd-storage-account-portal.primary_access_key
  service_plan_id            = azurerm_service_plan.func_app.id

  site_config {
    application_stack {
      powershell_core_version = 7
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "mi_func_app" {
  scope                = azurerm_resource_group.resource_group_portal.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_function_app.func_app_portal.identity[0].principal_id
}
