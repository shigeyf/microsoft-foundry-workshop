// main.vnet.private_dns_zone.tf

// ============================================================================
// Private DNS Zone Configuration
// ============================================================================
//
// This module supports two modes:
//
// 1. Create new DNS Zones (use_existing_dns_zones = false, default)
//    - Creates Private DNS Zones in the workload subscription
//    - Creates VNet links in the same resource group as the DNS Zones
//
// 2. Use existing DNS Zones (use_existing_dns_zones = true)
//    - References existing Private DNS Zones from Connectivity subscription
//    - Creates VNet links in the Connectivity subscription's DNS Zone resource group
//    - VNet links are child resources of DNS Zones, so they must be created
//      in the same resource group where the DNS Zone exists
//    - Despite being in Connectivity subscription, VNet links are managed by this
//      Terraform state, so they will be deleted when this configuration is destroyed
//
// ============================================================================

// ============================================================================
// Data Sources for Existing Private DNS Zones (Connectivity Subscription)
// ============================================================================

data "azurerm_private_dns_zone" "existing_ai_services" {
  count               = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider            = azurerm.connectivity
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = var.connectivity_dns_zone_resource_group
}

data "azurerm_private_dns_zone" "existing_cognitive" {
  count               = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider            = azurerm.connectivity
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.connectivity_dns_zone_resource_group
}

data "azurerm_private_dns_zone" "existing_openai" {
  count               = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider            = azurerm.connectivity
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.connectivity_dns_zone_resource_group
}

data "azurerm_private_dns_zone" "existing_keyvault" {
  count               = local.enable_private_networking && local.use_existing_dns_zones && var.enable_cmk ? 1 : 0
  provider            = azurerm.connectivity
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.connectivity_dns_zone_resource_group
}

data "azurerm_private_dns_zone" "existing_search" {
  count               = local.enable_private_networking && local.use_existing_dns_zones && var.enable_ai_search ? 1 : 0
  provider            = azurerm.connectivity
  name                = "privatelink.search.windows.net"
  resource_group_name = var.connectivity_dns_zone_resource_group
}

// ============================================================================
// New Private DNS Zones (created when not using existing zones)
// ============================================================================

// Private DNS Zone for AI Services (Microsoft Foundry)
resource "azurerm_private_dns_zone" "ai_services" {
  count               = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

// ============================================================================
// VNet Links for New DNS Zones (workload subscription)
// ============================================================================

// VNet link for AI Services (new DNS Zone)
resource "azurerm_private_dns_zone_virtual_network_link" "ai_services" {
  count                 = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                  = "vnet-link-ai-services-${local.rand_id}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = var.tags
}

// ============================================================================
// VNet Links for Existing DNS Zones (Connectivity subscription)
// These are created in Connectivity subscription but managed by this Terraform.
// When this Terraform is destroyed, these links will be removed automatically.
// ============================================================================

// VNet link for AI Services (existing DNS Zone in Connectivity subscription)
resource "azurerm_private_dns_zone_virtual_network_link" "ai_services_existing" {
  count                 = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider              = azurerm.connectivity
  name                  = "vnet-link-ai-services-${local.rand_id}"
  resource_group_name   = var.connectivity_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_ai_services[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
}

// Private DNS Zone for Cognitive Services (Microsoft Foundry)
resource "azurerm_private_dns_zone" "cognitive" {
  count               = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive" {
  count                 = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                  = "vnet-link-cognitive-${local.rand_id}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_existing" {
  count                 = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider              = azurerm.connectivity
  name                  = "vnet-link-cognitive-${local.rand_id}"
  resource_group_name   = var.connectivity_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_cognitive[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
}

// Private DNS Zone for OpenAI (required for Microsoft Foundry)
resource "azurerm_private_dns_zone" "openai" {
  count               = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  count                 = local.enable_private_networking && !local.use_existing_dns_zones ? 1 : 0
  name                  = "vnet-link-openai-${local.rand_id}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.openai[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_existing" {
  count                 = local.enable_private_networking && local.use_existing_dns_zones ? 1 : 0
  provider              = azurerm.connectivity
  name                  = "vnet-link-openai-${local.rand_id}"
  resource_group_name   = var.connectivity_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_openai[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
}

// Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  count               = local.enable_private_networking && !local.use_existing_dns_zones && var.enable_cmk ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  count                 = local.enable_private_networking && !local.use_existing_dns_zones && var.enable_cmk ? 1 : 0
  name                  = "vnet-link-keyvault-${local.rand_id}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_existing" {
  count                 = local.enable_private_networking && local.use_existing_dns_zones && var.enable_cmk ? 1 : 0
  provider              = azurerm.connectivity
  name                  = "vnet-link-keyvault-${local.rand_id}"
  resource_group_name   = var.connectivity_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_keyvault[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
}

// Private DNS Zone for AI Search
resource "azurerm_private_dns_zone" "search" {
  count               = local.enable_private_networking && !local.use_existing_dns_zones && var.enable_ai_search ? 1 : 0
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  count                 = local.enable_private_networking && !local.use_existing_dns_zones && var.enable_ai_search ? 1 : 0
  name                  = "vnet-link-search-${local.rand_id}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.search[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "search_existing" {
  count                 = local.enable_private_networking && local.use_existing_dns_zones && var.enable_ai_search ? 1 : 0
  provider              = azurerm.connectivity
  name                  = "vnet-link-search-${local.rand_id}"
  resource_group_name   = var.connectivity_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.existing_search[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
}
