variable "environment" {
  description = "Target environment name."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

variable "resource_tags" {
  description = "Default tags to apply to resources."
  type        = map(string)
  default = {
    service    = "aks-gitops-demo"
    managed-by = "terraform"
    project    = "aks-appgw-flux-demo"
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group where demo resources are provisioned."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "West Europe"
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

  validation {
    condition     = length(trimspace(var.vnet_name)) > 0
    error_message = "vnet_name must not be empty."
  }
}

variable "vnet_cidr" {
  description = "Address space for the virtual network when create_vnet is true."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.create_vnet == false || can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr must be a valid IPv4 CIDR block when create_vnet is true."
  }
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
  description = "Address prefix for the Application Gateway for Containers subnet. Must be at least /28."
  type        = string
  default     = ""
}

variable "admin_group_object_ids" {
  description = "Object IDs of Entra ID groups that receive AKS cluster admin access."
  type        = list(string)
  default     = []
}

variable "enable_flux" {
  description = "Enable AKS Flux GitOps configurations for external app repositories."
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

  validation {
    condition     = var.enable_flux == false || length(var.flux_repositories) > 0
    error_message = "flux_repositories must contain at least one repository when enable_flux is true."
  }

  validation {
    condition = alltrue([
      for name, repo in var.flux_repositories :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", name)) && length(name) <= 63
    ])
    error_message = "flux_repositories keys must be valid Kubernetes-style names: lowercase letters, numbers, hyphens, max 63 characters."
  }
}
