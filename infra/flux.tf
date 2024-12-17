resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "${var.k8s_name}-flux"
  cluster_id     = azurerm_kubernetes_cluster.aks.id
  extension_type = "microsoft.flux"

  configuration_settings = {
    "image-automation-controller.enabled" = true,
    "image-reflector-controller.enabled"  = true,
    "notification-controller.enabled"     = true,
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.app_node_pool]
}

resource "azurerm_kubernetes_flux_configuration" "flux_config" {
  depends_on = [
    azurerm_kubernetes_cluster_extension.flux
  ]

  name       = "aks-flux-extension"
  cluster_id = azurerm_kubernetes_cluster.aks.id
  namespace  = "flux-system"
  scope      = "cluster"
  continuous_reconciliation_enabled = true

  git_repository {
    url                      = "https://github.com/GroupThreeSix/fluxcd-manifest"
    reference_type           = "branch"
    reference_value          = "master"
    timeout_in_seconds       = 600
    sync_interval_in_seconds = 30
    https_user = var.github_user
    https_key_base64 = base64encode(var.github_token)
  }

  kustomizations {
    name = "apps-staging"
    path = "apps/staging"

    timeout_in_seconds         = 600
    sync_interval_in_seconds   = 30
    retry_interval_in_seconds  = 300
    garbage_collection_enabled = true
  }

  kustomizations {
    name = "apps-production"
    path = "apps/production"

    timeout_in_seconds         = 600
    sync_interval_in_seconds   = 30
    retry_interval_in_seconds  = 300
    garbage_collection_enabled = true
  }
}
