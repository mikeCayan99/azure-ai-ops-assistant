output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}