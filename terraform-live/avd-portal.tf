resource "azurerm_resource_group" "resource_group_portal" {
  name     = local.resource_group_name_portal
  location = var.location
  tags = {
    "Environment" : var.environment
  }
}

resource "azurerm_storage_account" "storage_account_portal" {
  name                     = local.avd_storage_account_portal
  location                 = azurerm_resource_group.resource_group_portal.location
  resource_group_name      = azurerm_resource_group.resource_group_portal.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

resource "azurerm_storage_queue" "queue" {
  for_each             = toset(var.queue_list)
  name                 = each.value
  storage_account_name = azurerm_storage_account.storage_account_portal.name
}

resource "azurerm_application_insights" "application_insights" {
  name                = local.application_insights_portal
  resource_group_name = azurerm_resource_group.resource_group_portal.name
  location            = azurerm_resource_group.resource_group_portal.location
  application_type    = "web"
}


resource "azurerm_service_plan" "func_app" {
  name                = local.service_plan_portal
  resource_group_name = azurerm_resource_group.resource_group_portal.name
  location            = azurerm_resource_group.resource_group_portal.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "func_app_portal" {
  name                = local.function_app_portal
  resource_group_name = azurerm_resource_group.resource_group_portal.name
  location            = azurerm_resource_group.resource_group_portal.location

  storage_account_name       = azurerm_storage_account.storage_account_portal.name
  storage_account_access_key = azurerm_storage_account.storage_account_portal.primary_access_key
  service_plan_id            = azurerm_service_plan.func_app.id
  site_config {
    application_stack {
      powershell_core_version = "7"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "powershell"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key
    "STORAGE_ACCOUNT_NAME"           = azurerm_storage_account.storage_account_portal.name
    "STORAGE_ACCOUNT_KEY"            = azurerm_storage_account.storage_account_portal.primary_access_key
  }

  identity {
    type = "SystemAssigned"
  }
}

#Fix PowerShel version issue
#https://github.com/hashicorp/terraform-provider-azurerm/issues/8867
resource "null_resource" "fix_powershell_version" {
  provisioner "local-exec" {
    command = <<-EOT
      
 az functionapp update --name ${azurerm_windows_function_app.func_app_portal.name} --resource-group ${azurerm_resource_group.resource_group_portal.name} --set siteConfig.powerShellVersion=7.2
    EOT
  }
  depends_on = [azurerm_windows_function_app.func_app_portal]
  triggers = {
    build_number = "1"
  }
}

resource "azurerm_role_assignment" "mi_resource_group_portal" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_function_app.func_app_portal.identity[0].principal_id
}
