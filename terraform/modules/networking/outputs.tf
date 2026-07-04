output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = local.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = local.vnet_name
}

output "vnet_resource_group_name" {
  description = "Resource group name of the virtual network."
  value       = local.vnet_resource_group
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet."
  value       = local.aks_subnet_id
}

output "alb_subnet_id" {
  description = "Resource ID of the subnet delegated to Application Gateway for Containers."
  value       = azurerm_subnet.alb.id
}
