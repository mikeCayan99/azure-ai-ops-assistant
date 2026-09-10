resource "azurerm_resource_group" "main" {
  name     = "rg-ai-ops-dev"
  location = "Germany West Central"
}

resource "azurerm_container_registry" "main" {
  name                = "acraiopsmikedev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

