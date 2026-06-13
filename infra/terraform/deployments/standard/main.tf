# main.tf — Basic Deployment
#
# Modules used in this tier:
#   - observability     (Log Analytics + Application Insights)
#   - foundry-core      (Foundry Account + Project + Deployments + BYO KV)
#   - foundry-agents    (ACR + Capability Host)
#   - rbac              (User/group role assignments)

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Observability (Log Analytics + Application Insights)
# ---------------------------------------------------------------------------

module "observability" {
  source = "../../modules/observability"
  count  = var.enable_observability ? 1 : 0

  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  tags                         = local.tags
  log_analytics_workspace_name = local.names.log_analytics
  application_insights_name    = local.names.application_insights

  use_existing              = !var.create_observability
  existing_log_workspace_id = var.existing_log_workspace_id
  existing_app_insights_id  = var.existing_app_insights_id
}

# ---------------------------------------------------------------------------
# Foundry Core (Account + Project + Model Deployments + Connections)
# ---------------------------------------------------------------------------

module "foundry_core" {
  source = "../../modules/foundry-core"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  # Foundry Account
  account_name = local.names.foundry_account

  # Foundry Project
  project_name         = local.names.foundry_project
  project_display_name = var.foundry_project_display_name
  project_description  = var.foundry_project_description

  # Model Deployments
  model_deployments = var.model_deployments

  # Application Insights connection
  enable_app_insights_connection = var.enable_observability
  app_insights_id                = var.enable_observability ? module.observability[0].app_insights_id : ""
  app_insights_name              = var.enable_observability ? module.observability[0].app_insights_name : ""
  app_insights_connection_string = var.enable_observability ? module.observability[0].app_insights_connection_string : ""

  # BYO Key Vault (optional)
  enable_keyvault = var.enable_byo_keyvault
  key_vault_name  = var.enable_byo_keyvault ? local.names.key_vault : ""
}

# ---------------------------------------------------------------------------
# Foundry Agents (ACR + Capability Host)
# ---------------------------------------------------------------------------

module "foundry_agents" {
  source = "../../modules/foundry-agents"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  foundry_account_id = module.foundry_core.foundry_account_id
  # Container Registry
  registry_name = local.names.container_registry

  # RBAC: Foundry Project MI → ACR
  foundry_project_principal_id = module.foundry_core.foundry_project_principal_id
}

module "foundry_agents_standard" {
  source = "../../modules/foundry-agents-byo"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  # BYO resources for Foundry Agents
  file_storage_account_name   = local.names.file_storage_account_name
  vector_store_account_name   = local.names.vector_store_account_name
  thread_storage_account_name = local.names.thread_storage_account_name

  # Capability Host
  foundry_account_id = module.foundry_core.foundry_account_id
  foundry_project_id = module.foundry_core.foundry_project_id

  # RBAC: Foundry Project MI → ACR
  foundry_project_principal_id = module.foundry_core.foundry_project_principal_id
}

# ---------------------------------------------------------------------------
# RBAC (User/group role assignments)
# ---------------------------------------------------------------------------

module "rbac" {
  source = "../../modules/rbac"

  foundry_account_id    = module.foundry_core.foundry_account_id
  foundry_project_id    = module.foundry_core.foundry_project_id
  container_registry_id = module.foundry_agents.registry_id

  enable_keyvault = var.enable_byo_keyvault
  key_vault_id    = module.foundry_core.key_vault_id

  deployer_principal_id      = coalesce(var.deployer_object_id, data.azurerm_client_config.current.object_id)
  deployer_use_foundry_owner = var.deployer_use_foundry_owner
  foundry_developer_group_id = try(data.azuread_group.developers[0].object_id, "")
  foundry_user_group_id      = try(data.azuread_group.users[0].object_id, "")
}
