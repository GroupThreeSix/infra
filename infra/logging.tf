resource "azurerm_log_analytics_workspace" "k8s" {
  location            = var.location
  name                = "${var.k8s_name}-logs"
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = "PerGB2018"
}