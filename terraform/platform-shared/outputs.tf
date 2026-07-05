output "resource_group_name" {
  description = "Resource group name."
  value       = var.resource_group_name
}

output "location" {
  description = "Azure region."
  value       = var.location
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster."
  value       = module.aks.aks_cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.aks_cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster."
  value       = module.aks.aks_oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "Auto-generated AKS node resource group name."
  value       = module.aks.node_resource_group
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.networking.vnet_id
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet."
  value       = module.networking.aks_subnet_id
}





output "flux_configuration_ids" {
  description = "IDs of Flux configurations keyed by external app name."
  value       = { for name, config in azurerm_kubernetes_flux_configuration.apps : name => config.id }
}

output "flux_repository_deploy_public_keys" {
  description = "OpenSSH public deploy keys keyed by Flux repository name. Add each value to its matching GitHub repo as a read-only deploy key before or immediately after apply."
  value       = { for name, key in tls_private_key.flux_repository : name => key.public_key_openssh }
}
