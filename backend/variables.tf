variable "location" {
  type        = string
  description = "The Azure region where resources should be created"
  default     = "koreacentral"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure resource group name"
  default     = "terraform-state-rg"
}

variable "storage_account_name" {
  type        = string
  description = "The Azure storage account name"
  default     = "tfstategroup36"
}

variable "container_name" {
  type        = string
  description = "The Azure storage container name"
  default     = "tfstategroup36"
}

variable "acr_resource_group_name" {
  type = string
  default = "group36-acr"
}