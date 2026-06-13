# variables.users.tf — User/group RBAC parameters

variable "deployer_principal_id" {
  description = "Principal ID of the deployer (empty string to skip)"
  type        = string
  default     = ""
}

variable "deployer_use_foundry_owner" {
  description = "If true, assign Foundry Owner (full access incl. data plane) to deployer instead of Foundry Account Owner (control plane only)"
  type        = bool
  default     = false
}

variable "foundry_developer_group_id" {
  description = "Object ID of the Foundry Developer group — assigned Foundry Project Manager role (empty string to skip)"
  type        = string
  default     = ""
}

variable "foundry_user_group_id" {
  description = "Object ID of the Foundry User group — assigned Reader on account + Foundry User on project (empty string to skip)"
  type        = string
  default     = ""
}
