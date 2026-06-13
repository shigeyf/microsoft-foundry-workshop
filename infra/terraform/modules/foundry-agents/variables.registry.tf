# variables.registry.tf — Container Registry parameters

variable "registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "sku" {
  description = "ACR SKU: Basic | Standard | Premium. Auto-upgraded to Premium when CMK is enabled"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Whether to enable admin user (recommended false for production)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = <<-EOT
    Whether to enable public network access.
    Note: Hosted Agent requires ACR to be publicly accessible.
  EOT
  type        = bool
  default     = true
}
