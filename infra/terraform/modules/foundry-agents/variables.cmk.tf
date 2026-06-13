# variables.cmk.tf — Customer Managed Key (CMK) parameters for ACR (optional)
# CMK is enabled when acr_cmk_key_vault_key_versionless_id is non-empty.
# RBAC (UAMI → Key Vault: Key Vault Crypto Service Encryption User) must be
# configured externally before calling this module.

variable "acr_cmk_user_assigned_identity_id" {
  description = "Resource ID of the UAMI for ACR CMK encryption"
  type        = string
  default     = ""
}

variable "acr_cmk_user_assigned_identity_client_id" {
  description = "Client ID of the UAMI for ACR CMK encryption"
  type        = string
  default     = ""
}

variable "acr_cmk_key_vault_key_id" {
  description = "Key Vault Key ID for ACR CMK (versioned or versionless). Non-empty value enables CMK."
  type        = string
  default     = ""
}
