variable "aks_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "istio_revisions" {
  type        = list(string)
  description = "Istio control plane revisions for the AKS service mesh add-on"
  default     = ["asm-1-27"]
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}


variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for the AKS default node pool"
}

variable "vm_size" {
  type        = string
  description = "VM size for the default node pool"
  default     = "Standard_D2s_v3"
}

variable "min_count" {
  type        = number
  description = "Minimum node count for default node pool autoscaling"
  default     = 2
  validation {
    condition     = var.min_count >= 2
    error_message = "The minimum node count must be at least 2."
  }
}

variable "max_count" {
  type        = number
  description = "Maximum node count for default node pool autoscaling"
  default     = 2
  validation {
    condition     = var.max_count <= 2
    error_message = "The maximum node count must be 2 or less for this demo environment limit."
  }
}

variable "enable_istio" {
  type        = bool
  description = "Toggle to enable/disable AKS Istio service mesh add-on"
  default     = true
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster"
  default     = []
}
