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

# resource "azurerm_network_security_group" "aks_nsg" {
#   name                = var.cluster_network_security_name
#   location            = azurerm_resource_group.cluster_manager.location
#   resource_group_name = azurerm_resource_group.cluster_manager.name

#   dynamic "security_rule" {
#     for_each = var.cluster_network_security_rules

#     content {
#       name                       = security_rule.value.sg_name
#       priority                   = security_rule.value.sg_priority
#       direction                  = security_rule.value.sg_direction
#       access                     = security_rule.value.sg_access
#       protocol                   = security_rule.value.sg_protocol
#       source_port_range          = security_rule.value.sg_source_port_range
#       destination_port_range     = security_rule.value.sg_destination_port_range
#       source_address_prefix      = security_rule.value.sg_source_address_prefix
#       destination_address_prefix = security_rule.value.sg_destination_address_prefix
#     }
#   }

#   depends_on = [azurerm_resource_group.cluster_manager]
# }

# resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg_association" {
#   subnet_id                 = azurerm_subnet.aks_subnet.id
#   network_security_group_id = azurerm_network_security_group.aks_nsg.id

#   depends_on = [azurerm_network_security_group.aks_nsg, azurerm_subnet.aks_subnet]
# }