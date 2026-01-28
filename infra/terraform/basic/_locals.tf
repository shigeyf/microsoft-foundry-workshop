// _locals.tf

// Naming variables for AI Foundry resources
locals {
  resource_short_name = substr(local.resource_suffix_hash, 0, 16)

  resource_group_name         = "rg-${join("-", local.resource_suffix)}-${local.rand_id}"
  cognitive_account_name      = "cogacct-${join("-", local.resource_suffix)}-${local.rand_id}"
  cognitive_project_name      = "proj-${join("-", local.resource_suffix)}-${local.rand_id}"
  cognitive_uami_name         = "uami-${join("-", local.resource_suffix)}-${local.rand_id}"
  search_service_name         = "srch-${join("-", local.resource_suffix)}-${local.rand_id}"
  vnet_name                   = "vnet-${join("-", local.resource_suffix)}-${local.rand_id}"
  loganalytics_workspace_name = "law-${join("-", local.resource_suffix)}-${local.rand_id}"
  application_insights_name   = "appi-${join("-", local.resource_suffix)}-${local.rand_id}"
  key_vault_name              = "kv-${local.resource_short_name}${local.rand_id}"
  storage_account_name        = "st${local.resource_short_name}${local.rand_id}"
}

// Network isolation mode derived values
locals {
  // Whether to create VNet, PE, and private DNS zones
  enable_private_networking = var.network_isolation_mode != "public"

  // Value for public_network_access_enabled attribute of each resource
  public_network_access_enabled = var.network_isolation_mode != "private"

  // Whether to use existing Private DNS Zones from Connectivity subscription
  use_existing_dns_zones = var.use_existing_private_dns_zones && var.connectivity_subscription_id != "" && var.connectivity_dns_zone_resource_group != ""
}

// Private DNS Zone IDs - unified references for both new and existing zones
locals {
  private_dns_zone_id_ai_services = local.enable_private_networking ? (
    local.use_existing_dns_zones
    ? data.azurerm_private_dns_zone.existing_ai_services[0].id
    : azurerm_private_dns_zone.ai_services[0].id
  ) : null

  private_dns_zone_id_cognitive = local.enable_private_networking ? (
    local.use_existing_dns_zones
    ? data.azurerm_private_dns_zone.existing_cognitive[0].id
    : azurerm_private_dns_zone.cognitive[0].id
  ) : null

  private_dns_zone_id_openai = local.enable_private_networking ? (
    local.use_existing_dns_zones
    ? data.azurerm_private_dns_zone.existing_openai[0].id
    : azurerm_private_dns_zone.openai[0].id
  ) : null

  private_dns_zone_id_keyvault = local.enable_private_networking && var.enable_cmk ? (
    local.use_existing_dns_zones
    ? data.azurerm_private_dns_zone.existing_keyvault[0].id
    : azurerm_private_dns_zone.keyvault[0].id
  ) : null

  private_dns_zone_id_search = local.enable_private_networking && var.enable_ai_search ? (
    local.use_existing_dns_zones
    ? data.azurerm_private_dns_zone.existing_search[0].id
    : azurerm_private_dns_zone.search[0].id
  ) : null
}
