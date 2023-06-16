# Storage Account

## Attachments
resource "azurerm_storage_account" "stor" {
  name                     = format("%s%s1stordemo", var.customer, var.environment)
  resource_group_name      = data.azurerm_resource_group.rg-core.name
  location                 = data.azurerm_resource_group.rg-core.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"
  minimum_tls_version      = "1.2"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
