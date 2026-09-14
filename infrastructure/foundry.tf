data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "main" {
  name                     = "aiopsstorageacct"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "aiopsassistant"
  }
}

resource "azurerm_key_vault" "main" {
  name                       = "aiopskeyvault"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  rbac_authorization_enabled = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

}


resource "azurerm_cognitive_account" "main" {
  name                       = "aiopscognitiveacct"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  kind                       = "AIServices"
  sku_name                   = "S0"
  project_management_enabled = true
  custom_subdomain_name      = "aiopscognitiveacct-subdomain"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account_project" "main" {
  name                 = "aiops-project"
  cognitive_account_id = azurerm_cognitive_account.main.id
  location             = azurerm_resource_group.main.location
  description          = "AI Ops cognitive services project"
  display_name         = "AI Ops Project"

  identity {
    type = "SystemAssigned"
  }

}