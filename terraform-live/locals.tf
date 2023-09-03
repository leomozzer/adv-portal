locals {
  resource_group_name                                  = "rg-${var.location_short}-${var.app_name}-01"
  virtual_network_name                                 = "vnet-${var.location_short}-${var.app_name}-01"
  virtual_network_subnet_desktop_name                  = "snet-desktop"
  virtual_desktop_workspace_name                       = "ws-${var.location_short}-${var.app_name}-01"
  virtual_desktop_workspace_friendly_name              = "AVD Workspace"
  virtual_desktop_host_pool_name                       = "hostpool-${var.location_short}-${var.app_name}-01"
  virtual_desktop_host_pool_registration_info_duration = "24h"
  azurerm_virtual_desktop_application_group_name       = "appgroup-${var.location_short}-${var.app_name}-01"
  avd_key_vault_name                                   = "kv-${var.location_short}-${var.app_name}-01"
  avd_storage_account_name                             = "sta${var.location_short}${var.app_name}01"
}
