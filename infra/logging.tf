resource "azurerm_log_analytics_workspace" "k8s" {
  location            = var.location_monitoring
  name                = "${var.k8s_name}-logs"
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = "PerGB2018"
}

resource "azurerm_monitor_workspace" "k8s" {
  name                          = "amon-${var.k8s_name}"
  resource_group_name           = azurerm_resource_group.k8s.name
  location                      = var.location_monitoring
  public_network_access_enabled = true

  depends_on = [
    azurerm_resource_group.k8s
  ]
}

resource "azurerm_monitor_data_collection_endpoint" "k8s_msprom" {
  name                = "MSProm-${var.location}-${var.k8s_name}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = var.location_monitoring
  kind                = "Linux"
}


resource "azurerm_monitor_data_collection_rule" "k8s_msprom" {
  name                        = "MSProm-${var.location}-${var.k8s_name}"
  resource_group_name         = azurerm_resource_group.k8s.name
  location                    = var.location_monitoring
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.k8s_msprom.id
  kind                        = "Linux"
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.k8s.id
      name               = azurerm_monitor_workspace.k8s.name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [azurerm_monitor_workspace.k8s.name]
  }

  depends_on = [time_sleep.wait_60_seconds]
}

resource "azurerm_monitor_data_collection_rule_association" "k8s_dcr_to_aks" {
  name                    = "MSProm-${var.location}-${var.k8s_name}"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.k8s_msprom.id

  lifecycle {
    replace_triggered_by = [azurerm_monitor_data_collection_rule.k8s_msprom]
  }

  depends_on = [
    azurerm_monitor_data_collection_rule.k8s_msprom,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_dashboard_grafana" "k8s" {
  name                              = "${var.k8s_name}-dg"
  resource_group_name               = azurerm_resource_group.k8s.name
  location                          = var.location_monitoring
  grafana_major_version             = "10"
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.k8s.id
  }
}

resource "azurerm_role_assignment" "k8s_amg_me" {
  scope                = azurerm_dashboard_grafana.k8s.id
  role_definition_name = "Grafana Admin"
  principal_id         = "4c603abb-6833-4865-879e-7243c7a5c1cf"

  depends_on = [
    azurerm_dashboard_grafana.k8s
  ]
}

resource "azurerm_role_assignment" "k8s_rg_amg" {
  principal_id         = azurerm_dashboard_grafana.k8s.identity[0].principal_id
  role_definition_name = "Monitoring Data Reader"
  scope                = azurerm_resource_group.k8s.id

  depends_on = [
    azurerm_dashboard_grafana.k8s
  ]
}

resource "azurerm_role_assignment" "k8s_rd_amg" {
  principal_id         = azurerm_dashboard_grafana.k8s.identity[0].principal_id
  role_definition_name = "Monitoring Reader"
  scope                = data.azurerm_subscription.current.id

  depends_on = [
    azurerm_dashboard_grafana.k8s
  ]
}

resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
  depends_on      = [azurerm_log_analytics_workspace.k8s, azurerm_monitor_data_collection_endpoint.k8s_msprom]
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node" {
  name                = "NodeRecordingRulesRuleGroup-${var.k8s_name}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = var.location_monitoring
  cluster_name        = azurerm_kubernetes_cluster.aks.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.k8s.id]

  rule {
    enabled    = true
    record     = "instance:node_num_cpu:sum"
    expression = "count without (cpu, mode) (node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
  }

  rule {
    enabled    = true
    record     = "instance:node_cpu_utilisation:rate5m"
    expression = "1 - avg without (cpu) (sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
  }

  rule {
    enabled    = true
    record     = "instance:node_load1_per_cpu:ratio"
    expression = "(node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
  }

  rule {
    enabled    = true
    record     = "instance:node_memory_utilisation:ratio"
    expression = "1 - ((node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) / node_memory_MemTotal_bytes{job=\"node\"})"
  }

  rule {
    enabled    = true
    record     = "instance:node_vmstat_pgmajfault:rate5m"
    expression = "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
  }

  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_seconds:rate5m"
    expression = "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
  }

  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
    expression = "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
  }

  rule {
    enabled    = true
    record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    enabled    = true
    record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    enabled    = true
    record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    enabled    = true
    record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  depends_on = [
    azurerm_monitor_workspace.k8s,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_monitor_alert_prometheus_rule_group" "k8s" {
  name                = "KubernetesRecordingRulesRuleGroup-${var.k8s_name}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = var.location_monitoring
  cluster_name        = azurerm_kubernetes_cluster.aks.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.k8s.id]

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
    expression = "sum by (cluster, namespace, pod, container) (irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }


  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_working_set_bytes"
    expression = "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_rss"
    expression = "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_cache"
    expression = "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_swap"
    expression = "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
    expression = "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"} * on(namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_requests:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
    expression = "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
    expression = "sum by (namespace, cluster) (sum by(namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
    expression = "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_limits:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
    expression = "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
  }

  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"}, \"replicaset\", \"$1\", \"owner_name\", \"(.*)\") * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (1, max by (replicaset, namespace, owner_name) (kube_replicaset_owner{job=\"kube-state-metrics\"})), \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "deployment"
    }
  }

  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "daemonset"
    }
  }

  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "statefulset"
    }
  }

  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "job"
    }
  }

  rule {
    enabled    = true
    record     = ":node_memory_MemAvailable_bytes:sum"
    expression = "sum(node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) by (cluster)"
  }

  rule {
    enabled    = true
    record     = "cluster:node_cpu:ratio_rate5m"
    expression = "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
  }

  depends_on = [
    azurerm_monitor_workspace.k8s,
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_monitor_data_collection_rule" "msci" {
  name                = "MSCI-${var.location}-${var.k8s_name}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = var.location_monitoring
  kind                = "Linux"

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = <<JSON
      {
        "dataCollectionSettings": {
          "interval": "1m",
          "namespaceFilteringMode": "Off",
          "enableContainerLogV2": true
        }
      }
      JSON
    }
  }

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.k8s.id
      name                  = azurerm_log_analytics_workspace.k8s.name
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = [azurerm_log_analytics_workspace.k8s.name]
  }

  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "msci_to_aks" {
  name                    = "msci-${var.k8s_name}"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.msci.id

  lifecycle {
    replace_triggered_by = [azurerm_monitor_data_collection_rule.msci]
  }

  depends_on = [
    azurerm_monitor_data_collection_rule.msci,
    azurerm_kubernetes_cluster.aks
  ]
}