# outputs.tf

# --- Resource names (pre-built, CAF-compliant) ---

output "resource_names" {
  description = "Map of pre-built resource names for all common resource types"
  value       = local.resource_names
}

# --- Naming pattern outputs (for deployment-specific resources) ---

output "hyphen_hash_name" {
  description = "DNS-globally unique name with hyphens and hash suffix"
  value       = local.hyphen_hash_name
}

output "hyphen_name" {
  description = "Scope-unique name with hyphens (no hash)"
  value       = local.hyphen_name
}

output "alphanum_hash_name" {
  description = "DNS-globally unique name, alphanumeric only, with hash suffix"
  value       = local.alphanum_hash_name
}

output "alphanum_name" {
  description = "Scope-unique name, alphanumeric only (no hash)"
  value       = local.alphanum_name
}

output "alphanum_name_fix20" {
  description = "DNS-globally unique name, alphanumeric only, fixed 20 chars (hash + instance)"
  value       = local.alphanum_name_fix20
}

# --- CAF abbreviation and rule outputs ---

output "abbreviations" {
  description = "Map of CAF resource type abbreviations (e.g., key_vault = \"kv\", storage_account = \"st\")"
  value       = module.caf_naming.abbreviations
}

output "rules" {
  description = "Naming constraint rules per resource type (max_length, scope, etc.)"
  value       = module.caf_naming.rules
}

# --- Tags ---

output "tags" {
  description = "Merged tags including governance tags, optional well-known tags, and extra tags"
  value       = local.tags
}

# --- Hash outputs ---

output "hash6" {
  description = "6-character deterministic hash"
  value       = local.hash6
}

output "hash_alphanum" {
  description = "Deterministic hash for alphanum names (20 - instance_padding chars)"
  value       = local.hash_alphanum
}

output "unique_string" {
  description = "13-character deterministic hash (ARM uniqueString compatible length)"
  value       = module.caf_naming.unique_string
}

output "instance" {
  description = "Zero-padded instance number (instance_padding digits)"
  value       = module.caf_naming.instance
}

# --- Region utility outputs ---

output "region" {
  description = "Full region information object from AVM regions module (includes geo_code, paired_region_name, zones, etc.)"
  value       = module.azure_regions.regions_by_name[var.location]
}

output "location_short" {
  description = "Azure region short name / geo code (e.g., eastus -> eus, japaneast -> jae)"
  value       = local.location_short_name
}

output "random_id" {
  description = "Random string for additional uniqueness"
  value       = local.rand_id
}
