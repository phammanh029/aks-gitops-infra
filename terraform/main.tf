# Terraform root configuration for JTL Platform Shop Infra
terraform {
  required_version = ">= 1.15.7"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
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
  default_tags {
    tags = local.tags
  }
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

provider "kubernetes" {
  host                   = "https://${module.platform_shared.aks_fqdn}:443"
  cluster_ca_certificate = base64decode(module.platform_shared.aks_cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630",
      "--client-id",
      data.azurerm_client_config.current.client_id,
      "--tenant-id",
      data.azurerm_client_config.current.tenant_id,
      "--login",
      "azurecli"
    ]
  }
}

# Platform Shared module instantiating shared platform resources once
module "platform_shared" {
  source              = "./platform-shared"
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_redis        = var.enable_redis
  enable_postgres     = var.enable_postgres

  # Network posture: private by default; may enable limited public access via tfvars.
  redis_public_network_access_enabled      = var.redis_public_network_access_enabled
  postgres_public_network_access_enabled   = var.postgres_public_network_access_enabled
  postgres_firewall_allowed_ips            = var.postgres_firewall_allowed_ips
  servicebus_public_network_access_enabled = var.servicebus_public_network_access_enabled
  servicebus_local_auth_enabled            = var.servicebus_local_auth_enabled
  redis_name                               = var.redis_name
  postgres_name                            = var.postgres_name
  postgres_admin_user                      = var.postgres_admin_user
  postgres_admin_password                  = var.postgres_admin_password
  servicebus_name                          = var.servicebus_name
  aks_name                                 = var.aks_name
  gateway_name                             = var.gateway_name
  create_vnet                              = var.create_vnet
  vnet_name                                = var.vnet_name
  vnet_cidr                                = var.vnet_cidr
  vnet_resource_group_name                 = var.vnet_resource_group_name
  aks_subnet_name                          = var.aks_subnet_name
  ingress_subnet_name                      = var.ingress_subnet_name
  ingress_subnet_cidr                      = var.ingress_subnet_cidr
  alb_subnet_name                          = var.alb_subnet_name
  alb_subnet_cidr                          = var.alb_subnet_cidr
  registry_name                            = var.registry_name
  admin_group_object_ids                   = var.admin_group_object_ids
  tags                                     = local.tags
}

# Service composition: Admin
module "admin_service" {
  source                        = "./services/admin"
  environment                   = var.environment
  resource_group_name           = var.resource_group_name
  location                      = var.location
  aks_cluster_name              = module.platform_shared.aks_cluster_name
  aks_oidc_issuer_url           = module.platform_shared.aks_oidc_issuer_url
  servicebus_topic_receiver_ids = var.admin_servicebus_topic_receiver_ids
  servicebus_topic_sender_ids   = var.admin_servicebus_topic_sender_ids
  redis_cache_id                = module.platform_shared.redis_cache_id
  postgres_server_id            = module.platform_shared.postgres_server_id
  postgres_enabled              = var.enable_postgres
  tags                          = local.tags
}

# Service composition: Storefront
module "storefront_service" {
  source                        = "./services/storefront"
  environment                   = var.environment
  resource_group_name           = var.resource_group_name
  location                      = var.location
  aks_cluster_name              = module.platform_shared.aks_cluster_name
  aks_oidc_issuer_url           = module.platform_shared.aks_oidc_issuer_url
  servicebus_topic_receiver_ids = var.storefront_servicebus_topic_receiver_ids
  servicebus_topic_sender_ids   = var.storefront_servicebus_topic_sender_ids
  redis_cache_id                = module.platform_shared.redis_cache_id
  postgres_server_id            = module.platform_shared.postgres_server_id
  postgres_enabled              = var.enable_postgres
  gateway_id                    = module.platform_shared.gateway_id
  alb_subnet_id                 = module.platform_shared.alb_subnet_id
  tags                          = local.tags
}

# Service composition: ERP Connector
module "erp_connector_service" {
  source                        = "./services/erp-connector"
  environment                   = var.environment
  resource_group_name           = var.resource_group_name
  location                      = var.location
  aks_cluster_name              = module.platform_shared.aks_cluster_name
  aks_oidc_issuer_url           = module.platform_shared.aks_oidc_issuer_url
  servicebus_topic_receiver_ids = var.erp_connector_servicebus_topic_receiver_ids
  servicebus_topic_sender_ids   = var.erp_connector_servicebus_topic_sender_ids
  redis_cache_id                = module.platform_shared.redis_cache_id
  postgres_server_id            = module.platform_shared.postgres_server_id
  postgres_enabled              = var.enable_postgres
  tags                          = local.tags
}
