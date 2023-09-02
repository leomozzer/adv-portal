locals {
  resource_group_name                                  = "rg-${var.location_short}-${var.app_name}-01"
  virtual_network_name                                 = "vnet-${var.location_short}-${var.app_name}-01"
  virtual_network_subnet_desktop_name                  = "snet-desktop"
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

resource "azurerm_virtual_network" "network_vnet" {
  name                = local.virtual_network_name
  address_space       = [var.network_vnet_cidr[0]]
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
}

# Create a subnet for VM
resource "azurerm_subnet" "desktop_subnet" {
  name                 = local.virtual_network_subnet_desktop_name
  address_prefixes     = [var.network_subnet_cidr[0]]
  virtual_network_name = azurerm_virtual_network.network_vnet.name
  resource_group_name  = azurerm_resource_group.resource_group.name
}

#set DNS 
# resource "azurerm_virtual_network_dns_servers" "DNS_CUSTOM" {
#   virtual_network_id = azurerm_virtual_network.network_vnet.id
#   dns_servers        = [var.ad_dc1_ip_address]
# }

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
