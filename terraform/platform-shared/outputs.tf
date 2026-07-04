output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.aks_cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.aks_cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster"
  value       = module.aks.aks_oidc_issuer_url
}

output "servicebus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = module.servicebus.servicebus_id
}

output "redis_cache_id" {
  description = "ID of the Redis cache"
  value       = var.enable_redis ? module.redis[0].redis_id : ""
}

output "postgres_server_id" {
  description = "ID of the PostgreSQL server"
  value       = var.enable_postgres ? module.postgres[0].postgres_id : ""
}

# Network Outputs
output "vnet_id" {
  description = "Resource ID of the Virtual Network (Created or Imported)"
  value       = module.networking.vnet_id
}

output "alb_subnet_id" {
  description = "Resource ID of the ALB subnet (delegated to Microsoft.ServiceNetworking/trafficControllers)"
  value       = module.networking.alb_subnet_id
}

output "app_gateway_subnet_id" {
  description = "Alias output for the Application Gateway / ALB subnet ID"
  value       = module.networking.app_gateway_subnet_id
}

output "ingress_subnet_id" {
  description = "Resource ID of the ingress subnet"
  value       = module.networking.ingress_subnet_id
}

output "traefik_frontend_ip" {
  description = "Calculated 4th IP address of the ingress subnet reserved for the Traefik Gateway"
  value       = module.networking.traefik_frontend_ip
}

output "aks_host" {
  description = "Kubernetes API host endpoint"
  value       = module.aks.aks_host
}

output "aks_client_certificate" {
  description = "Base64 encoded client certificate"
  value       = module.aks.aks_client_certificate
  sensitive   = true
}

output "aks_client_key" {
  description = "Base64 encoded client key"
  value       = module.aks.aks_client_key
  sensitive   = true
}

output "aks_cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = module.aks.aks_cluster_ca_certificate
  sensitive   = true
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.aks_fqdn
}

output "gateway_id" {
  description = "Resource ID of the Application Gateway for Containers (ALB)"
  value       = azurerm_application_load_balancer.this.id
}

output "gateway_name" {
  description = "Name of the Application Gateway for Containers (ALB)"
  value       = azurerm_application_load_balancer.this.name
}

output "gateway_frontend_name" {
  description = "Frontend name of the Application Gateway for Containers (ALB)"
  value       = azurerm_application_load_balancer_frontend.this.name
}
