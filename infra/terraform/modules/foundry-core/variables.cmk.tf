# variables.cmk.tf — Customer Managed Key (CMK) parameters for Foundry Account (optional)
# CMK is enabled when foundry_cmk_key_vault_key_id is non-empty.
# RBAC (UAMI → Key Vault: Key Vault Crypto Service Encryption User) must be
# configured externally before calling this module.

variable "foundry_cmk_user_assigned_identity_id" {
  description = "Resource ID of the UAMI for Foundry Account CMK encryption"
  type        = string
  default     = ""
}

variable "foundry_cmk_user_assigned_identity_client_id" {
  description = "Client ID of the UAMI for Foundry Account CMK encryption"
  type        = string
  default     = ""
}

variable "foundry_cmk_key_vault_key_id" {
  description = "Key Vault Key ID for Foundry Account CMK (versioned). Non-empty value enables CMK."
  type        = string
  default     = ""
}
