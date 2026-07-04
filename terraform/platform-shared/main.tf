terraform {
  required_version = ">= 1.15.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

module "networking" {
  source = "../modules/networking"

  resource_group_name      = var.resource_group_name
  location                 = var.location
  create_vnet              = var.create_vnet
  vnet_name                = var.vnet_name
  vnet_cidr                = var.vnet_cidr
  vnet_resource_group_name = var.vnet_resource_group_name
  aks_subnet_name          = var.aks_subnet_name
  tags                     = var.tags
}

module "aks" {
  source = "../modules/aks"

  aks_name               = var.aks_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  vnet_subnet_id         = module.networking.aks_subnet_id
  min_count              = 2
  max_count              = 2
  enable_istio           = false
  admin_group_object_ids = var.admin_group_object_ids
  tags                   = var.tags
}


resource "azurerm_kubernetes_cluster_extension" "flux" {
  count = var.enable_flux ? 1 : 0

  name           = "flux"
  cluster_id     = module.aks.aks_cluster_id
  extension_type = "microsoft.flux"

  configuration_settings = {
    "multiTenancy.enforce" = "false"
  }
}

moved {
  from = azurerm_kubernetes_flux_configuration.storefront[0]
  to   = azurerm_kubernetes_flux_configuration.apps["storefront"]
}

resource "azurerm_kubernetes_flux_configuration" "apps" {
  for_each = var.enable_flux ? var.flux_repositories : {}

  name       = each.key
  cluster_id = module.aks.aks_cluster_id
  namespace  = var.flux_namespace
  scope      = "cluster"

  git_repository {
    url             = each.value.url
    reference_type  = "branch"
    reference_value = each.value.branch
  }

  kustomizations {
    name                       = each.key
    path                       = each.value.path
    sync_interval_in_seconds   = each.value.sync_interval_in_seconds
    retry_interval_in_seconds  = each.value.retry_interval_in_seconds
    timeout_in_seconds         = each.value.timeout_in_seconds
    garbage_collection_enabled = each.value.garbage_collection_enabled
  }

  depends_on = [
    azurerm_kubernetes_cluster_extension.flux
  ]
}
