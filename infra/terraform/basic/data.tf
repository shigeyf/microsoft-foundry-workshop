// data.tf

data "azurerm_client_config" "current" {}

data "azuread_group" "ai_developer_group" {
  display_name     = var.ai_project_developers_group_name
  security_enabled = true
}
