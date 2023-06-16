terraform {
  backend "azurerm" {
    container_name = "tfstate-dnug-demo"
    use_oidc       = true
  }
}
