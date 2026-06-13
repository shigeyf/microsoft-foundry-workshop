# variables.keyvault.tf — BYO Key Vault parameters for Foundry connections

variable "enable_keyvault" {
  description = "Whether to create a Key Vault for Foundry connection secrets (BYO Key Vault)"
  type        = bool
  default     = false
}

variable "key_vault_name" {
  description = "Name of the Key Vault. Required when enable_keyvault is true."
  type        = string
  default     = ""
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU: standard or premium (premium adds HSM-backed keys)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "key_vault_sku_name must be 'standard' or 'premium'."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft-delete retention in days (7-90)"
  type        = number
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "key_vault_soft_delete_retention_days must be between 7 and 90."
  }
}

variable "key_vault_enable_purge_protection" {
  description = "Enable purge protection. Required for production environments."
  type        = bool
  default     = false
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether to enable public network access for the Key Vault"
  type        = bool
  default     = true
}
