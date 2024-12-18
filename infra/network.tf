resource "azurerm_virtual_network" "vnet" {
  name                = "${var.k8s_name}-vnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  tags = var.tags_resource_environment

  depends_on = [azurerm_resource_group.k8s]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.k8s_name}-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.30.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}