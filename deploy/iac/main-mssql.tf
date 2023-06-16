resource "azurerm_mssql_server" "mssql" {
  name                         = format("%s-%s-sql-dnugdemo", var.customer, var.environment)
  resource_group_name          = data.azurerm_resource_group.rg-core.name
  location                     = data.azurerm_resource_group.rg-core.location
  version                      = "12.0"
  administrator_login          = var.mssql_login
  administrator_login_password = var.mssql_login_pwd
  minimum_tls_version          = "1.2"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}