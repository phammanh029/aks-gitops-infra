terraform {
  required_version = ">= 1.15.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Validation rule in main.tf to fail if registry variable is missing
# FR-008: The feature MUST prevent implicit fallback behavior that creates replacement shared resources when external inputs are missing.
resource "null_resource" "registry_validation" {
  lifecycle {
    precondition {
      condition     = var.registry_name != ""
      error_message = "ERROR: Hub registry reference (registry_name) must be supplied. Creating a registry or falling back is not allowed."
    }
  }
}

# Reusable module composition: Networking (VNet, Subnets, Delegation, Ingress IP calculation)
module "networking" {
  source                   = "../modules/networking"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  create_vnet              = var.create_vnet
  vnet_name                = var.vnet_name
  vnet_cidr                = var.vnet_cidr
  vnet_resource_group_name = var.vnet_resource_group_name
  aks_subnet_name          = var.aks_subnet_name
  ingress_subnet_name      = var.ingress_subnet_name
  ingress_subnet_cidr      = var.ingress_subnet_cidr
  alb_subnet_name          = var.alb_subnet_name
  alb_subnet_cidr          = var.alb_subnet_cidr
  tags                     = var.tags
}

# AKS Cluster module composition
module "aks" {
  source                 = "../modules/aks"
  aks_name               = var.aks_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  vnet_subnet_id         = module.networking.aks_subnet_id
  min_count              = 2
  max_count              = 10
  enable_istio           = var.environment == "prod"
  admin_group_object_ids = var.admin_group_object_ids
  tags                   = var.tags
}

# Application Gateway for Containers (AGFC) - Dedicated for Shop Ingress
# (exposed by azurerm as "application load balancer" / traffic controller resources)
resource "azurerm_application_load_balancer" "this" {
  name                = var.gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# AGFC Subnet Association
resource "azurerm_application_load_balancer_subnet_association" "this" {
  name                         = "${var.gateway_name}-association"
  application_load_balancer_id = azurerm_application_load_balancer.this.id
  subnet_id                    = module.networking.alb_subnet_id
}

# AGFC Frontend (logical point for listeners, configured via alb-controller)
resource "azurerm_application_load_balancer_frontend" "this" {
  name                         = "${var.gateway_name}-frontend"
  application_load_balancer_id = azurerm_application_load_balancer.this.id
  tags                         = var.tags
}

# Traefik Gateway API manifest provisioned dynamically with calculated 4th IP
resource "kubernetes_manifest" "traefik_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "shared-gateway"
      namespace = "kube-system"
      annotations = {
        "service.beta.kubernetes.io/azure-load-balancer-internal"        = "true"
        "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = var.ingress_subnet_name
        "service.beta.kubernetes.io/azure-load-balancer-ipv4"            = module.networking.traefik_frontend_ip
      }
    }
    spec = {
      gatewayClassName = "traefik"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchExpressions = [
                  {
                    key      = "kubernetes.io/metadata.name"
                    operator = "In"
                    values   = ["admin", "admin-pr"]
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}


# Reusable module composition: Redis (Azure Managed Redis)
module "redis" {
  count                         = var.enable_redis ? 1 : 0
  source                        = "../modules/redis"
  redis_name                    = var.redis_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = var.redis_public_network_access_enabled
  tags                          = var.tags
}

# Reusable module composition: PostgreSQL Flexible Server
module "postgres" {
  count                         = var.enable_postgres ? 1 : 0
  source                        = "../modules/postgres"
  postgres_name                 = var.postgres_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  admin_user                    = var.postgres_admin_user
  admin_password                = var.postgres_admin_password
  public_network_access_enabled = var.postgres_public_network_access_enabled
  firewall_allowed_ips          = var.postgres_firewall_allowed_ips
  tags                          = var.tags
}

# Reusable module composition: Service Bus Namespace
module "servicebus" {
  source                        = "../modules/servicebus"
  servicebus_name               = var.servicebus_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = var.servicebus_public_network_access_enabled
  local_auth_enabled            = var.servicebus_local_auth_enabled
  tags                          = var.tags
}

# Grant Azure Service Bus Data Owner to admin/developer groups so users can send/receive messages locally via RBAC
resource "azurerm_role_assignment" "servicebus_admin_data_owner" {
  for_each             = toset(var.admin_group_object_ids)
  scope                = module.servicebus.servicebus_id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value
}


# Private DNS Zones and Private Endpoints for Platform Services
# Zones/endpoints are created only when the service runs privately (qa/prod posture);
# dev may switch a service to limited public access instead.
locals {
  redis_private    = var.enable_redis && !var.redis_public_network_access_enabled
  postgres_private = var.enable_postgres && !var.postgres_public_network_access_enabled
}

resource "azurerm_private_dns_zone" "redis" {
  count               = local.redis_private ? 1 : 0
  name                = "privatelink.redis.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "postgres" {
  count               = local.postgres_private ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Service Bus Private Endpoints and Private DNS Zone are disabled for now.
# Rationale: Azure Service Bus Private Endpoints require the Premium SKU (~$677+/month),
# which is cost-prohibitive compared to the Standard SKU (~$10/month) used in this baseline.
# When upgrading to Premium SKU in the future, uncomment this DNS zone and attach the private endpoint.
# resource "azurerm_private_dns_zone" "servicebus" {
#   name                = "privatelink.servicebus.windows.net"
#   resource_group_name = var.resource_group_name
#   tags                = var.tags
# }



resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count                 = local.redis_private ? 1 : 0
  name                  = "${var.redis_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = data.azurerm_virtual_network.this.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = local.postgres_private ? 1 : 0
  name                  = "${var.postgres_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = data.azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "redis" {
  count = local.redis_private ? 1 : 0
  name  = "${var.redis_name}-pe"
  # TODO: Move private endpoints to a dedicated subnet once core-infra provides one.
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.aks.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.redis_name}-psc"
    private_connection_resource_id = module.redis[0].redis_id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  private_dns_zone_group {
    name                 = "${var.redis_name}-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
  }
}

resource "azurerm_private_endpoint" "postgres" {
  count               = local.postgres_private ? 1 : 0
  name                = "${var.postgres_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.aks.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.postgres_name}-psc"
    private_connection_resource_id = module.postgres[0].postgres_id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "${var.postgres_name}-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgres[0].id]
  }
}

# ClusterRole for writing HTTPRoute resources
resource "kubernetes_cluster_role" "httproute_writer" {
  metadata {
    name = "httproute-writer"
  }

  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["httproutes"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# ClusterRole for reading HTTPRoute resources
resource "kubernetes_cluster_role" "httproute_reader" {
  metadata {
    name = "httproute-reader"
  }

  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["httproutes"]
    verbs      = ["get", "list", "watch"]
  }
}
