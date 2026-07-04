# Root Outputs for JTL Platform Shop Infra

output "vnet_id" {
  description = "Resource ID of the Virtual Network (Created or Imported)"
  value       = module.platform_shared.vnet_id
}

output "alb_subnet_id" {
  description = "Resource ID of the ALB subnet provisioned with ServiceNetworking/trafficControllers delegation"
  value       = module.platform_shared.alb_subnet_id
}

output "app_gateway_subnet_id" {
  description = "Alias output for the Application Gateway / ALB subnet ID"
  value       = module.platform_shared.app_gateway_subnet_id
}

output "ingress_subnet_id" {
  description = "Resource ID of the ingress subnet"
  value       = module.platform_shared.ingress_subnet_id
}

output "traefik_frontend_ip" {
  description = "Calculated 4th IP address of the ingress subnet reserved for the Traefik Gateway"
  value       = module.platform_shared.traefik_frontend_ip
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.platform_shared.aks_cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.platform_shared.aks_cluster_name
}

output "gateway_id" {
  description = "Resource ID of the Application Gateway for Containers (ALB)"
  value       = module.platform_shared.gateway_id
}

output "gateway_name" {
  description = "Name of the Application Gateway for Containers (ALB)"
  value       = module.platform_shared.gateway_name
}
