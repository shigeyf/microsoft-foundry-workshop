# locals.tf

# --- Naming module ---
module "naming" {
  source = "../../conventions/az-naming"

  subscription_id = local.subscription_id
  workload        = var.workload
  project         = var.project
  environment     = var.env
  location        = var.location

  use_hash_for_rg = var.use_hash_for_resource_group

  extra_tags = var.tags

  # Optional tag parameters
  owner               = var.owner
  cost_center         = var.cost_center
  business_unit       = var.business_unit
  criticality         = var.criticality
  data_classification = var.data_classification
  expiry_date         = var.expiry_date
}

locals {
  # Resolved subscription ID (from variable or current client)
  subscription_id = var.target_subscription_id != "" ? var.target_subscription_id : data.azurerm_client_config.current.subscription_id

  # Resource names from naming module
  names = module.naming.resource_names

  # Tags from naming module
  tags = module.naming.tags
}
