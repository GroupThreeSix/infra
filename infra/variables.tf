variable "location" {
  type        = string
  description = "The Azure region where resources should be created"
  default     = "japaneast"
}

variable "location_monitoring" {
  type        = string
  description = "The Azure region where resources should be created"
  default     = "japaneast"
}

variable "acr_resource_group_name" {
  type    = string
  default = "group36-acr"
}

variable "k8s_resource_group_name" {
  type        = string
  description = "The Azure Kubernetes Service virtual network resource group name"
  default     = "group36-k8s-rg"
}

variable "k8s_name" {
  type        = string
  description = "The Azure Kubernetes Service API subnet name"
  default     = "group36-k8s"
}

variable "cluster_dns_prefix" {
  description = "The DNS prefix to use for the Kubernetes cluster."
  type        = string
  default     = "group36mngcluster"
}

variable "cluster_version" {
  description = "Version of the Kubernetes cluster to be created."
  type        = string
  default     = "1.30"
}

variable "cluster_network_service_cidr" {
  description = "The CIDR block for the Kubernetes service network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_network_dns_service_ip" {
  description = "The IP address for the DNS service within the Kubernetes service network."
  type        = string
  default     = "10.0.0.10"
}

variable "cluster_network_pod_cidr" {
  description = "The CIDR block for the Kubernetes pod network."
  type        = string
  default     = "10.244.0.0/16"
}

variable "cluster_network_type_load_balancer_sku" {
  description = "SKU type of the load balancer to be used, either 'standard' or 'basic'."
  type        = string
  default     = "standard"
}

variable "cluster_nodepool_name" {
  description = "The name of the default node pool in the Kubernetes cluster."
  type        = string
  default     = "systemnodes"
}

variable "cluster_nodepool_autoscaling_enabled" {
  description = "Flag to enable or disable autoscaling for the default node pool."
  type        = bool
  default     = true
}

variable "cluster_nodepool_autoscaling_min_count" {
  description = "Minimum number of nodes for the default node pool when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "cluster_nodepool_autoscaling_max_count" {
  description = "Maximum number of nodes for the default node pool when autoscaling is enabled."
  type        = number
  default     = 2
}

variable "agents_size" {
  default     = "Standard_B2s_v2"
  description = "The default virtual machine size for the Kubernetes agents"
  type        = string
}

variable "cluster_additional_nodepool_name" {
  description = "The name of the additional node pool for running application workloads."
  type        = string
  default     = "usernodes"
}

variable "cluster_additional_nodepool_autoscaling_enabled" {
  description = "Flag to enable or disable autoscaling for the additional node pool."
  type        = bool
  default     = false
}

variable "cluster_additional_nodepool_autoscaling_min_count" {
  description = "Minimum number of nodes for the additional node pool when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "cluster_additional_nodepool_autoscaling_max_count" {
  description = "Maximum number of nodes for the additional node pool when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "cluster_additional_nodepool_labels" {
  description = "Labels to assign to the additional node pool for identification and organization."
  type        = map(string)
  default = {
    environment = "applications"
  }
}

variable "tags_resource_environment" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    environment = "development"
    owner       = "devops-team"
    project     = "platform-engineering"
  }
}

variable "github_user" {
  type        = string
  description = "The GitHub username"
}

variable "github_token" {
  type        = string
  description = "The GitHub token"
}