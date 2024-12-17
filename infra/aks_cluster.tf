resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.k8s_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix          = var.cluster_dns_prefix
  kubernetes_version  = var.cluster_version

  default_node_pool {
    name                 = var.cluster_nodepool_name
    vm_size              = var.agents_size
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    auto_scaling_enabled = var.cluster_nodepool_autoscaling_enabled
    min_count            = var.cluster_nodepool_autoscaling_enabled ? var.cluster_nodepool_autoscaling_min_count : null
    max_count            = var.cluster_nodepool_autoscaling_enabled ? var.cluster_nodepool_autoscaling_max_count : null
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    service_cidr        = var.cluster_network_service_cidr
    dns_service_ip      = var.cluster_network_dns_service_ip
    pod_cidr            = var.cluster_network_pod_cidr
    load_balancer_sku   = var.cluster_network_type_load_balancer_sku
  }

  service_mesh_profile {
    mode = "Istio"
    revisions = [
      "asm-1-23" 
    ]
    external_ingress_gateway_enabled = true
    internal_ingress_gateway_enabled = true
  }

  private_cluster_enabled = false
  tags                    = var.tags_resource_environment

  depends_on = [azurerm_subnet.aks_subnet]
}