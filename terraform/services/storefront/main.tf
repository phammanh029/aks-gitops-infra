terraform {
  required_version = ">= 1.0"
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

# Call generic service baseline module
module "service_baseline" {
  source                        = "../../modules/service"
  service_name                  = "storefront"
  environment                   = var.environment
  resource_group_name           = var.resource_group_name
  location                      = var.location
  aks_cluster_name              = var.aks_cluster_name
  aks_oidc_issuer_url           = var.aks_oidc_issuer_url
  servicebus_topic_receiver_ids = var.servicebus_topic_receiver_ids
  servicebus_topic_sender_ids   = var.servicebus_topic_sender_ids
  redis_cache_id                = var.redis_cache_id
  postgres_server_id            = var.postgres_server_id
  postgres_enabled              = var.postgres_enabled
  tags                          = var.tags
}

# Grant Storefront workload identity permissions to manage Application Gateway for Containers (ALB)
resource "azurerm_role_assignment" "alb_configuration_manager" {
  scope                = var.gateway_id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = module.service_baseline.service_identity_principal_id
}

resource "azurerm_role_assignment" "alb_subnet_contributor" {
  scope                = var.alb_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.service_baseline.service_identity_principal_id
}
