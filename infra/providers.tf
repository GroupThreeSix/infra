terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
    azapi = {
      source = "azure/azapi"
      version = "2.1.0"
    }
  }

  backend "azurerm" {

  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "c4b3fd2e-e809-401f-b436-462924dadfee"
}