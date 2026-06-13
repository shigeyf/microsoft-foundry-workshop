# variables.tf — foundry-agents-byo module common parameters

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "foundry_account_id" {
  description = "Resource ID of the Foundry Account (parent for capability host)"
  type        = string
}

variable "foundry_project_id" {
  description = "Resource ID of the Foundry Project (parent for capability host)"
  type        = string
}

# variable "foundry_account_principal_id" {
#   description = "System-assigned MI principal ID of the Foundry Account"
#   type        = string
# }

variable "foundry_project_principal_id" {
  description = "System-assigned MI principal ID of the Foundry Project"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Whether to enable public network access"
  type        = bool
  default     = true
}
