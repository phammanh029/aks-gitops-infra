output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "Auto-generated node resource group name"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "aks_host" {
  description = "Kubernetes API host endpoint"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
}

output "aks_client_certificate" {
  description = "Base64 encoded client certificate"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "aks_client_key" {
  description = "Base64 encoded client key"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "aks_cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}
