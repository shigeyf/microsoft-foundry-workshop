// _locals.tf

// Naming variables for AI Foundry resources
locals {
  resource_group_name         = "rg-${local.resource_long_name}"
  cognitive_account_name      = "cogacct-${local.resource_long_name}"
  cognitive_project_name      = "proj-${local.resource_simple_name}"
  uami_cmk_name               = "uami-cmk-${local.resource_long_name}"
  search_service_name         = "srch-${local.resource_long_name}"
  vnet_name                   = "vnet-${local.resource_long_name}"
  loganalytics_workspace_name = "log-${local.resource_long_name}"
  application_insights_name   = "appi-${local.resource_long_name}"
  key_vault_name              = "kv-${local.resource_short_name}"
  storage_account_name        = "st${local.resource_alphanum_name}"
  acr_name                    = "cr${local.resource_alphanum_name}"
}

// Configuration derived values
locals {
  // Whether to create VNet, PE, and private DNS zones
  enable_private_networking = var.network_isolation_mode != "public"

  // Value for public_network_access_enabled attribute of each resource
  public_network_access_enabled = var.network_isolation_mode != "private"

  // Whether to use existing Private DNS Zones from Connectivity subscription
  use_existing_dns_zones = var.use_existing_private_dns_zones && var.connectivity_subscription_id != "" && var.connectivity_dns_zone_resource_group != ""

  // Enable purge protection on Key Vault for production environments to prevent permanent deletion.
  // When disabled in dev/demo, the vault can be purged automatically via the provider's purge_soft_delete_on_destroy setting.
  keyvault_purge_protection_enabled = var.is_production || var.enable_cmk
}

// Build a clean tags map — merge base tags with non-empty optional tags,
// matching Bicep's union() pattern that omits keys with null values.
locals {
  tags = merge(
    var.tags,
    var.owner != "" ? { owner = var.owner } : {},
    var.cost_center != "" ? { costCenter = var.cost_center } : {},
    var.business_unit != "" ? { businessUnit = var.business_unit } : {},
    var.criticality != "" ? { criticality = var.criticality } : {},
    var.data_classification != "" ? { dataClassification = var.data_classification } : {},
    var.expiry_date != "" ? { expiryDate = var.expiry_date } : {},
  )
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
