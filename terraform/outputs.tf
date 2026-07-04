output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.platform_shared.vnet_id
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet."
  value       = module.platform_shared.aks_subnet_id
}


output "aks_cluster_id" {
  description = "ID of the AKS cluster."
  value       = module.platform_shared.aks_cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.platform_shared.aks_cluster_name
}




output "flux_configuration_ids" {
  description = "IDs of Flux configurations keyed by external app name."
  value       = module.platform_shared.flux_configuration_ids
}
