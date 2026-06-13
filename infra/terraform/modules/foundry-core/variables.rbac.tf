# variables.rbac.tf — RBAC propagation parameters

variable "rbac_propagation_wait_duration" {
  description = "Duration to wait for RBAC role assignment propagation (Azure RBAC is eventually consistent)"
  type        = string
  default     = "60s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.rbac_propagation_wait_duration))
    error_message = "Format: <number>s (e.g. '60s')"
  }
}
