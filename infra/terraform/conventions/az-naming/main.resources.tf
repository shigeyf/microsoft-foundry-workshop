# main.resources.tf

# --- Resource name construction ---
# Each resource name respects CAF abbreviation prefix + naming scope constraints.
locals {
  resource_names = {
    # Subscription scope (random_id appended when use_hash_for_rg is true)
    resource_group = (var.use_hash_for_rg
      ? "rg-${local.hyphen_base}-${local.rand_id}"
      : "rg-${local.hyphen_base}"
    )

    # Resource group scope
    foundry_account      = "aif-${local.hyphen_hash_name}"
    foundry_project      = "proj-${local.hyphen_hash_name}"
    log_analytics        = "log-${local.hyphen_hash_name}"
    application_insights = "appi-${local.hyphen_hash_name}"
    managed_identity     = "id-${local.hyphen_hash_name}"
    managed_identity_cmk = "id-cmk-${local.hyphen_hash_name}"

    # BYO resources for Foundry Agents (see module/foundry-agents/variables.tf for usage)
    file_storage_account_name   = substr("agtfile${local.hash16}", 0, 24)
    vector_store_account_name   = "agtvector-${local.hash16}"
    thread_storage_account_name = substr("agtthread-${local.hash16}", 0, 44)

    # Global scope — hyphens allowed
    cosmosdb_account = "cosmos-${local.hyphen_hash_name}"
    search_service   = "srch-${local.hyphen_hash_name}"

    # Global scope — strict length limit (max 24), alphanumeric + hyphens
    key_vault = substr("kv-${local.alphanum_name_fix20}", 0, 24)

    # Global scope — strict length limit (max 24), alphanumeric only
    storage_account = substr("st${local.alphanum_name_fix20}", 0, 24)

    # Global scope — strict length limit (max 50), alphanumeric only
    container_registry = substr("cr${local.alphanum_name_fix20}", 0, 50)
  }
}
