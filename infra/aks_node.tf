resource "azurerm_kubernetes_cluster_node_pool" "app_node_pool" {
  name                  = var.cluster_additional_nodepool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.agents_size
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  auto_scaling_enabled  = var.cluster_additional_nodepool_autoscaling_enabled
  min_count             = var.cluster_additional_nodepool_autoscaling_enabled ? var.cluster_additional_nodepool_autoscaling_min_count : null
  max_count             = var.cluster_additional_nodepool_autoscaling_enabled ? var.cluster_additional_nodepool_autoscaling_max_count : null
  tags                  = var.tags_resource_environment

  depends_on = [azurerm_kubernetes_cluster.aks]
}