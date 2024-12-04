resource "azurerm_container_registry" "acr" {
  name                = "groupthreesix"
  location            = var.location
  resource_group_name = azurerm_resource_group.acrrg.name
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_resource_group" "acrrg" {
  name = var.acr_resource_group_name
  location = var.location
}