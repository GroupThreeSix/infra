resource "azurerm_resource_group" "k8s" {
  name     = var.k8s_resource_group_name
  location = var.location
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_provider_registration" "alert" {
  name = "Microsoft.AlertsManagement"
}

resource "azurerm_resource_provider_registration" "dashboard" {
  name = "Microsoft.Dashboard"
}