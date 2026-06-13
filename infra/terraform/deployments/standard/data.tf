# data.tf — Data Sources

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Entra ID Group Lookups (resolved from display name)
# ---------------------------------------------------------------------------

data "azuread_group" "developers" {
  count        = var.foundry_developers_group_name != "" ? 1 : 0
  display_name = var.foundry_developers_group_name
}

data "azuread_group" "users" {
  count        = var.foundry_users_group_name != "" ? 1 : 0
  display_name = var.foundry_users_group_name
}
