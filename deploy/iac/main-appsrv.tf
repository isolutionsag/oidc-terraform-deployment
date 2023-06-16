# App Service Plan
resource "azurerm_service_plan" "appplan" {
  name                = format("%s-%s-appplan-demo", var.customer, var.environment)
  resource_group_name = data.azurerm_resource_group.rg-core.name
  location            = data.azurerm_resource_group.rg-core.location
  os_type             = "Windows"
  sku_name            = "F1"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


# App Service
resource "azurerm_windows_web_app" "appsrv-demo" {
  name                = format("%s-%s-appsrv-demo", var.customer, var.environment)
  location            = data.azurerm_resource_group.rg-core.location
  resource_group_name = data.azurerm_resource_group.rg-core.name
  service_plan_id     = azurerm_service_plan.appplan.id

  https_only = true
  site_config {
    always_on = false
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v7.0"
    }
    http2_enabled = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
