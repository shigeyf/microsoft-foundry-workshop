# variables.foundry.account.tf — Foundry Account parameters

variable "account_name" {
  description = "Name of the Foundry Account (AIServices)"
  type        = string
}

variable "sku_name" {
  description = "Foundry Account SKU (only S0 is supported)"
  type        = string
  default     = "S0"
}

variable "local_auth_enabled" {
  description = "Whether to enable local auth (API key). Recommended false (Entra ID auth only)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether to enable public network access"
  type        = bool
  default     = true
}
