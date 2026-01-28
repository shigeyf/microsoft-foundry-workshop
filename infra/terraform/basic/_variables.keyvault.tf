// _variables.keyvault.tf

variable "enable_cmk" {
  description = "Enable Customer Managed Key (CMK) for Foundry resource"
  type        = bool
  default     = false
}

variable "keyvault_enable_rbac_authorization" {
  description = "Enable RBAC authorization"
  type        = bool
  default     = true
}

variable "keyvault_enabled_for_deployment" {
  description = "Enable deployment"
  type        = bool
  default     = false
}
variable "keyvault_enabled_for_disk_encryption" {
  description = "Enable disk encryption"
  type        = bool
  default     = false
}

variable "keyvault_enabled_for_template_deployment" {
  description = "Enable template deployment"
  type        = bool
  default     = false
}

variable "keyvault_soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 7
}

variable "keyvault_rbac_propagation_wait_duration" {
  description = <<-EOT
    Duration to wait for Key Vault RBAC role assignments to propagate before proceeding with key operations.
    RBAC propagation can take time in Azure, particularly in large environments.
    Default is 120s for reliable deployments. Increase this value if you encounter permission errors
    during deployment. Format: <number>s (e.g., "120s", "180s")
  EOT
  type        = string
  default     = "120s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.keyvault_rbac_propagation_wait_duration))
    error_message = "The wait duration must be specified in seconds with format: <number>s (e.g., '120s')."
  }
}

variable "customer_managed_key_policy" {
  description = "Key policy for Customer Managed Key (CMK)"
  type = object({
    key_type        = string
    key_size        = optional(number, 2048)
    curve_type      = optional(string)
    expiration_date = optional(string, null)
    rotation_policy = optional(object({
      automatic = optional(object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string, "P30D")
      }))
      expire_after         = optional(string, "P180D")
      notify_before_expiry = optional(string, "P29D")
    }))
  })
  default = {
    key_type = "RSA"
    key_size = 4096
    rotation_policy = {
      automatic = {
        time_before_expiry = "P30D"
      }
      expire_after         = "P180D"
      notify_before_expiry = "P29D"
    }
  }
}
