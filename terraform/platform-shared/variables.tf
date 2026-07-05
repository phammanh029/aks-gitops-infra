variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "West Europe"
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "create_vnet" {
  description = "Set to true to provision a new virtual network; false to use an existing virtual network."
  type        = bool
  default     = true
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network when create_vnet is true."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vnet_resource_group_name" {
  description = "Resource group of the existing virtual network when create_vnet is false. Defaults to resource_group_name."
  type        = string
  default     = ""
}

variable "aks_subnet_name" {
  description = "Name of the AKS node subnet."
  type        = string
  default     = "snet-aks"
}

variable "admin_group_object_ids" {
  description = "Object IDs of Entra ID groups that receive AKS cluster admin access."
  type        = list(string)
  default     = []
}

variable "enable_flux" {
  description = "Enable AKS Flux GitOps configurations."
  type        = bool
  default     = true
}

variable "flux_namespace" {
  description = "Namespace for Flux extension/configuration."
  type        = string
  default     = "flux-system"
}

variable "generate_flux_ssh_keys" {
  description = "Generate one SSH deploy key per Flux repository and configure Flux to use it. Public keys must be added to the matching GitHub repos as read-only deploy keys before Flux can sync private repos."
  type        = bool
  default     = false
}

variable "flux_ssh_known_hosts" {
  description = "Optional SSH known_hosts content for Flux Git repositories. Leave empty to let the Flux configuration omit explicit host key pinning."
  type        = string
  default     = ""
}

variable "flux_repositories" {
  description = "External app repositories for Flux to sync. Keys become Flux configuration names and Terraform resource identity."
  type = map(object({
    url                        = string
    path                       = string
    branch                     = optional(string, "main")
    sync_interval_in_seconds   = optional(number, 60)
    retry_interval_in_seconds  = optional(number, 60)
    timeout_in_seconds         = optional(number, 600)
    garbage_collection_enabled = optional(bool, true)
  }))
  default = {}

}
