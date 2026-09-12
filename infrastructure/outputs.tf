output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}


output "managed_identity_id" {
  description = "Resource ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "container_app_environment_id" {
  description = "Resource ID of the Azure Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.main.name
}

