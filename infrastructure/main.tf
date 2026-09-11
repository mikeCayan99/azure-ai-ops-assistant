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

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-ai-ops-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku               = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_container_app_environment" "main" {
  name                = "cae-ai-ops-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  public_network_access = "Enabled"
}

resource "azurerm_container_app" "main" {
  name                         = "ca-ai-ops-api-dev"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name

  revision_mode = "Single"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.main.id
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "api"
      image  = "acraiopsmikedev.azurecr.io/azure-ai-ops-assistant:v1"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled           = true
    target_port                = 8000
    allow_insecure_connections = false


    traffic_weight {
      percentage = 100
    }
  }
}


resource "azurerm_role_assignment" "role" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

resource "azurerm_user_assigned_identity" "main" {
  location            = azurerm_resource_group.main.location
  name                = "id-ai-ops-api-dev"
  resource_group_name = azurerm_resource_group.main.name
}
