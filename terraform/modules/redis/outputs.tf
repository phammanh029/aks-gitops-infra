output "redis_name" {
  value       = azurerm_managed_redis.this.name
  description = "Name of the Managed Redis instance"
}

output "redis_id" {
  value       = azurerm_managed_redis.this.id
  description = "ID of the Managed Redis instance"
}

output "redis_hostname" {
  value       = azurerm_managed_redis.this.hostname
  description = "Hostname of the Managed Redis instance"
}
