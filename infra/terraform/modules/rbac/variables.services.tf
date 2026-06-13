# variables.services.tf — Scope parameters for user/group RBAC

variable "foundry_account_id" {
  description = "Resource ID of the Foundry Account (RBAC scope)"
  type        = string
}

variable "foundry_project_id" {
  description = "Resource ID of the Foundry Project (RBAC scope)"
  type        = string
}

variable "container_registry_id" {
  description = "Resource ID of the Container Registry (ACR) for developer RBAC scope"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault for deployer RBAC scope (empty string when Key Vault is not provisioned)"
  type        = string
  default     = ""
}

variable "enable_keyvault" {
  description = "Whether a Key Vault is provisioned. Controls deployer Key Vault Administrator assignment."
  type        = bool
  default     = false
}
