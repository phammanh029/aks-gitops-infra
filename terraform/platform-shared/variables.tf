variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_redis" {
  description = "Toggle to enable/disable Redis cache provisioning"
  type        = bool
}

variable "enable_postgres" {
  description = "Toggle to enable/disable PostgreSQL server provisioning"
  type        = bool
}

variable "environment" {
  description = "Environment name (e.g. dev, qa, prod)"
  type        = string
}

variable "redis_name" {
  description = "Name of the Redis cache"
  type        = string
}

variable "postgres_name" {
  description = "Name of the PostgreSQL server"
  type        = string
}

variable "postgres_admin_user" {
  description = "Admin username for PostgreSQL"
  type        = string
}

variable "postgres_admin_password" {
  description = "Admin password for PostgreSQL"
  type        = string
  sensitive   = true
}

# Network posture: private by default; dev may enable limited public access per service.
variable "redis_public_network_access_enabled" {
  description = "Allow public network access to Redis (dev convenience only; keep false in qa/prod)"
  type        = bool
  default     = false
}

variable "postgres_public_network_access_enabled" {
  description = "Allow public network access to PostgreSQL (dev convenience only; keep false in qa/prod)"
  type        = bool
  default     = false
}

variable "postgres_firewall_allowed_ips" {
  description = "Named IP ranges allowed through the PostgreSQL firewall when public access is enabled"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "servicebus_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "gateway_name" {
  description = "Name of the Application Gateway for Containers (AGFC)"
  type        = string
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


# User Story 2: External Hub Registry Variables
variable "registry_name" {
  description = "Name of the existing hub container registry (external dependency)"
  type        = string
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster"
  default     = []
}

variable "servicebus_public_network_access_enabled" {
  description = "Allow public network access to Service Bus (Required for Standard SKU and local dev access)"
  type        = bool
  default     = false
}

variable "servicebus_local_auth_enabled" {
  description = "Allow local SAS authentication on Service Bus (Useful for local dev debugging; keep disabled in qa/prod)"
  type        = bool
  default     = false
}
