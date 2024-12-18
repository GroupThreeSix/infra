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



########################################
## If using a custom default_node_pool_vnet_subnet_id id the AKS service principal
## will need access to interact with the subnet.  This means adding permissions for
## the AKS service principal with contributor access to the subnets.
##
## When creating an internal load balancer it needs to be able to read then create the load balancer in these subnets:
##  Warning  SyncLoadBalancerFailed  3s (x6 over 2m39s)  service-controller  Error syncing load balancer: failed to ensure load balancer: Retriable: false, RetryAfter: 0s, HTTPStatusCode: 403, RawError: {"error":{"code":"AuthorizationFailed","message":"The client '33e40745-8982-4a7c-a955-13d954023ced' with object id '33e40745-8982-4a7c-a955-13d954023ced' does not have authorization to perform action 'Microsoft.Network/virtualNetworks/subnets/read' over scope '/subscriptions/7b3b906c-8d7c-4ad2-9c2f-b22c195f610e/resourceGroups/RS-DEV-EASTUS2-AKS-01/providers/Microsoft.Network/virtualNetworks/VNET-DEV-EASTUS2-AKS-01/subnets/SNET-AKS-Private-1' or the scope is invalid. If access was recently granted, please refresh your credentials."}}
##
## Scope - the resource group
## Service principal - The AKS' service principal
########################################


resource "azurerm_role_assignment" "cluster_service_principal" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}