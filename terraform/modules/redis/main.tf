# Reusable Redis module (Azure Managed Redis)
resource "azurerm_managed_redis" "this" {
  name                      = var.redis_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.sku_name
  high_availability_enabled = var.high_availability_enabled

  # Private by default; dev may opt in to public access explicitly.
  public_network_access = var.public_network_access_enabled ? "Enabled" : "Disabled"
  tags                  = var.tags

  default_database {}
}

variable "redis_name" {
  description = "Name of the Managed Redis instance"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "Azure Managed Redis SKU (e.g. Balanced_B0, Balanced_B5, MemoryOptimized_M10)"
  type        = string
  default     = "Balanced_B0"
}

variable "high_availability_enabled" {
  description = "Enable high availability (changing forces replacement)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access (dev convenience only; keep disabled in qa/prod)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

