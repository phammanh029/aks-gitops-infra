variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
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
