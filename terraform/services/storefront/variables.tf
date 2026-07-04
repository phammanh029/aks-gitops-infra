variable "environment" {
  description = "Environment name (e.g. dev, qa, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster"
  type        = string
}

variable "servicebus_topic_receiver_ids" {
  description = "Resource IDs of Service Bus topics this service is allowed to consume from"
  type        = list(string)
  default     = []
}

variable "servicebus_topic_sender_ids" {
  description = "Resource IDs of Service Bus topics this service is allowed to publish to"
  type        = list(string)
  default     = []
}

variable "redis_cache_id" {
  description = "Resource ID of the shared Redis cache"
  type        = string
}

variable "postgres_server_id" {
  description = "Resource ID of the shared PostgreSQL server"
  type        = string
}

variable "postgres_enabled" {
  description = "Whether the shared PostgreSQL server is provisioned"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "gateway_id" {
  description = "Resource ID of the Application Gateway for Containers (ALB)"
  type        = string
}

variable "alb_subnet_id" {
  description = "Resource ID of the ALB subnet"
  type        = string
}
