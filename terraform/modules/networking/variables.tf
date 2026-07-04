variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_vnet" {
  description = "Set to true to provision a new Virtual Network; false to import an existing Virtual Network."
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "Name of the Virtual Network (Mandatory in all modes)"
  type        = string
  validation {
    condition     = length(trimspace(var.vnet_name)) > 0
    error_message = "ERROR: 'vnet_name' is mandatory and must not be empty."
  }
}

variable "vnet_cidr" {
  description = "Address space for the VNet (Required when create_vnet = true, e.g., '10.0.0.0/16')."
  type        = string
  default     = ""
  validation {
    condition     = var.create_vnet == false || (var.vnet_cidr != "" && can(cidrhost(var.vnet_cidr, 0)))
    error_message = "ERROR: 'vnet_cidr' must be a valid IPv4 CIDR block when 'create_vnet' is true."
  }
}

variable "vnet_resource_group_name" {
  description = "Resource Group of the Virtual Network (if different from resource_group_name)"
  type        = string
  default     = ""
}

variable "aks_subnet_name" {
  description = "Name of the subnet for AKS nodes (Mandatory in all modes)"
  type        = string
  validation {
    condition     = length(trimspace(var.aks_subnet_name)) > 0
    error_message = "ERROR: 'aks_subnet_name' is mandatory and must not be empty."
  }
}

variable "ingress_subnet_name" {
  description = "Name of the ingress subnet for Traefik and Gateway routing (Mandatory in all modes)"
  type        = string
  validation {
    condition     = length(trimspace(var.ingress_subnet_name)) > 0
    error_message = "ERROR: 'ingress_subnet_name' is mandatory and must not be empty."
  }
}

variable "ingress_subnet_cidr" {
  description = "Address prefix for the ingress subnet (Required when importing an existing VNet or overriding defaults)"
  type        = string
  default     = ""
}

variable "alb_subnet_name" {
  description = "Name of the subnet delegated to Application Gateway for Containers (Mandatory in all modes)"
  type        = string
  validation {
    condition     = length(trimspace(var.alb_subnet_name)) > 0
    error_message = "ERROR: 'alb_subnet_name' is mandatory and must not be empty."
  }
}

variable "alb_subnet_cidr" {
  description = "Address prefix (/28) for the ALB subnet"
  type        = string
  default     = ""
}
