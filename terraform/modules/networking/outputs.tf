output "vnet_id" {
  description = "Resource ID of the Virtual Network (Created or Imported)"
  value       = local.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = local.vnet_name
}

output "vnet_resource_group_name" {
  description = "Resource Group Name of the Virtual Network"
  value       = local.vnet_resource_group
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet"
  value       = local.aks_subnet_id
}

output "ingress_subnet_id" {
  description = "Resource ID of the ingress subnet"
  value       = local.ingress_subnet_id
}

output "ingress_subnet_cidr" {
  description = "Address prefix of the ingress subnet"
  value       = local.ingress_subnet_cidr
}

output "traefik_frontend_ip" {
  description = "Calculated 4th IP address of the ingress subnet reserved for the Traefik Gateway"
  value       = local.traefik_frontend_ip
}

output "alb_subnet_id" {
  description = "Resource ID of the ALB subnet provisioned with ServiceNetworking/trafficControllers delegation"
  value       = azurerm_subnet.alb.id
}

output "app_gateway_subnet_id" {
  description = "Alias output for the Application Gateway / ALB subnet ID"
  value       = azurerm_subnet.alb.id
}
