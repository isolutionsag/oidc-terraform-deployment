# Resource Group
data "azurerm_resource_group" "rg-core" {
  name = format("%s-%s-rg-core", var.customer, var.environment)
}
