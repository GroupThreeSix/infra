resource "azurerm_resource_group" "k8s" {
  name     = var.k8s_resource_group_name
  location = var.location
}