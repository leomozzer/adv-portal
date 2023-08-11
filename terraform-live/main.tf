locals {
  resource_group_name                                  = "rg-${var.location_short}-${var.app_name}-01"
  virtual_desktop_workspace_name                       = "ws-${var.location_short}-${var.app_name}-01"
  virtual_desktop_workspace_friendly_name              = "AVD Workspace"
  virtual_desktop_host_pool_name                       = "hostpool-${var.location_short}-${var.app_name}-01"
  virtual_desktop_host_pool_registration_info_duration = "24h"
  azurerm_virtual_desktop_application_group_name       = "appgroup-${var.location_short}-${var.app_name}-01"
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = var.location
  tags = {
    "Environment" : var.environment
  }
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = local.virtual_desktop_workspace
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  friendly_name       = local.friendly_name
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
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), local.virtual_desktop_host_pool_registration_info_duration)
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = azurerm_resource_group.resource_group.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool_persistent.id
  location            = var.location
  type                = "Desktop"
  name                = local.azurerm_virtual_desktop_application_group_name
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool, azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}
