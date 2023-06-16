provider "azurerm" {
  features {}
  client_id                  = var.clientId
  subscription_id            = var.subscriptionId
  tenant_id                  = var.tenantId
  skip_provider_registration = true
  use_oidc                   = true
}
