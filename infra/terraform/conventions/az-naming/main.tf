# main.tf

# Random string generation for additional uniqueness
resource "random_string" "random" {
  length  = var.random_length
  numeric = true
  lower   = true
  upper   = false
  special = false
}

# Azure region information (AVM utility module)
module "azure_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.12"

  region_filter    = [var.location]
  enable_telemetry = false
}

locals {
  rand_id             = random_string.random.result
  location_short_name = module.azure_regions.regions_by_name[var.location].geo_code

  seed_base = join("-", compact([
    var.workload,
    var.project,
    var.environment,
    local.location_short_name,
    var.use_hash_for_rg ? local.rand_id : "",
  ]))

  # Synthetic resource group ID (equivalent to ARM's resourceGroup().id)
  # NOTE: Uses raw var values intentionally — seed must be deterministic before sanitization.
  # Pattern: /subscriptions/{sub-id}/resourceGroups/rg-{workload}-{project}-{env}-{location_short}[-{random}]
  synthetic_resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-${local.seed_base}"
}

# CAF Naming utility module
module "caf_naming" {
  source = "github.com/shigeyf/terraform-azurerm-avm-utils-caf-naming?ref=v0.1.0"

  unique_string_seed = [local.synthetic_resource_group_id]
  sanitize_inputs = {
    workload    = var.workload
    project     = var.project
    environment = var.environment
  }
  instance_number  = var.instance_number
  instance_padding = var.instance_padding

  enable_telemetry = false
}

# Naming convention:
#
#   hyphen_hash_name    — DNS-globally unique, hyphens allowed, hash suffix appended
#                         Pattern: <workload>-<project>-<env>-<region_short>-<hash6>    (<=60 chars)
#   hyphen_name         — Scope-unique only (resource group or parent resource), no hash needed
#                         Pattern: <workload>-<project>-<env>-<region_short>            (<=60 chars)
#   alphanum_hash_name  — DNS-globally unique, no hyphens, with hash suffix
#                         Pattern: <workload><project><env><region_short><hash6>        (<=60 chars)
#   alphanum_name       — Scope-unique, no hyphens, no hash
#                         Pattern: <workload><project><env><region_short>
#   alphanum_name_fix20 — DNS-globally unique, no hyphens, fixed 20 chars (Storage, KV, ACR)
#                         Pattern: <hash(20-padding)><instance(padding)>        (= 20 chars)
locals {
  # Sanitized values from caf_naming module (lowercase alphanumeric only)
  s_workload    = module.caf_naming.sanitized["workload"]
  s_project     = module.caf_naming.sanitized["project"]
  s_environment = module.caf_naming.sanitized["environment"]

  # Hash generation using caf_naming module
  hash6         = module.caf_naming.h6
  hash16        = substr(module.caf_naming.hash_full, 0, 16)
  hash_alphanum = substr(module.caf_naming.hash_full, 0, 20 - var.instance_padding)

  # Base name components for resource naming (sanitized, no hash)
  base = [
    local.s_workload,
    local.s_project,
    local.s_environment,
    local.location_short_name
  ]

  # Hyphenated suffix using sanitized values
  hyphen_base = join("-", local.base)

  # Alphanum base (no hyphens, no hash)
  alphanum_base = join("", local.base)

  # Build naming patterns
  hyphen_hash_name    = "${local.hyphen_base}-${local.hash6}"
  hyphen_name         = local.hyphen_base
  alphanum_hash_name  = "${local.alphanum_base}${local.hash6}"
  alphanum_name       = local.alphanum_base
  alphanum_name_fix20 = "${local.hash_alphanum}${module.caf_naming.instance}" # fixed 20 chars
}
