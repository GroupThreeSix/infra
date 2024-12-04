data "azurerm_container_registry" "aks" {
  name                = "groupthreesix"
  resource_group_name = var.acr_resource_group_name
}

resource "azurerm_role_assignment" "aks" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}