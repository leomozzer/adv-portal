resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = var.location
  tags = {
    "Environment" : var.environment
  }
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = local.virtual_desktop_workspace_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  friendly_name       = local.virtual_desktop_workspace_friendly_name
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool_persistent" {
  resource_group_name              = azurerm_resource_group.resource_group.name
  location                         = var.location
  name                             = local.virtual_desktop_host_pool_name
  friendly_name                    = local.virtual_desktop_host_pool_name
  validate_environment             = true
  custom_rdp_properties            = "audiocapturemode:i:1;audiomode:i:0;"
  type                             = "Personal"
  load_balancer_type               = "Persistent"
  preferred_app_group_type         = "Desktop"
  personal_desktop_assignment_type = "Automatic"
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool_persistent.id
  expiration_date = timeadd(timestamp(), local.virtual_desktop_host_pool_registration_info_duration)
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = azurerm_resource_group.resource_group.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool_persistent.id
  location            = var.location
  type                = "Desktop"
  name                = local.azurerm_virtual_desktop_application_group_name
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool_persistent, azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}

resource "azurerm_key_vault" "avd-kv" {
  name                       = local.avd_key_vault_name
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Set",
      "Restore",
      "Delete"
    ]
  }
}

resource "azurerm_key_vault_secret" "secret-registrationinfo" {
  name         = "registrationinfo"
  value        = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
  key_vault_id = azurerm_key_vault.avd-kv
}
