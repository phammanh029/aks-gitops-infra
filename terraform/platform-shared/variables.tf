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

variable "gateway_name" {
  description = "Name of the Application Gateway for Containers resource."
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

variable "alb_subnet_name" {
  description = "Name of the subnet delegated to Application Gateway for Containers."
  type        = string
  default     = "snet-appgw-containers"
}

variable "alb_subnet_cidr" {
  description = "Address prefix for the Application Gateway for Containers subnet. Use at least /24 to provide the 250+ available IPs expected by AGC guidance."
  type        = string
  default     = ""
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
