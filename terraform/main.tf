terraform {
  required_version = ">= 1.15.7"
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  tags = merge(
    var.resource_tags,
    {
      environment = var.environment
    }
  )
}

provider "azurerm" {
  features {}
}

module "platform_shared" {
  source = "./platform-shared"

  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location

  aks_name                 = var.aks_name
  create_vnet              = var.create_vnet
  vnet_name                = var.vnet_name
  vnet_cidr                = var.vnet_cidr
  vnet_resource_group_name = var.vnet_resource_group_name
  aks_subnet_name          = var.aks_subnet_name
  admin_group_object_ids   = var.admin_group_object_ids

  enable_flux       = var.enable_flux
  flux_namespace    = var.flux_namespace
  flux_repositories = var.flux_repositories

  tags = local.tags
}
