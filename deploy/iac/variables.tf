variable "clientId" {
  type = string
}

variable "customer" {
  type    = string
  default = "dnug"
}

variable "location" {
  type    = string
  default = "SwitzerlandNorth"
}

variable "tenantId" {
  type        = string
  description = "The id of the tenant to deploy to."
}

variable "subscriptionId" {
  type        = string
  description = "The id of the subscription to deploy to."
}

variable "environment" {
  type        = string
  description = "The environment name (DEV, TEST, PROD). Always pick only the initial letter, i.e. d, t, p"
}

variable "default_tags" {
  type        = map(any)
  description = "The default tags for Azure resources"
}

variable "mssql_login" {
  type      = string
  sensitive = true
}

variable "mssql_login_pwd" {
  type      = string
  sensitive = true
}
