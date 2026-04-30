# _variables.tf

variable "target_subscription_id" {
  description = "Azure Subscription Id for the bootstrap resources. Leave empty to use the az login subscription"
  type        = string
  default     = ""

  validation {
    condition = (
      var.target_subscription_id == ""
      || can(regex(
        "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
        var.target_subscription_id,
      ))
    )
    error_message = "Azure subscription id must be a valid GUID"
  }
}

variable "naming_suffix" {
  description = "Naming suffix for the deployed resources"
  type        = list(string)
  default     = ["foundry", "aipoc"]
}

variable "env" {
  description = "Environment tag value for the deployed resources"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for the deployment"
  type        = string
}

variable "tags" {
  description = "Tags for the deployment"
  type        = map(string)
  default = {
    env     = "dev"
    project = "foundry"
    purpose = "aipoc"
  }
}

# --- Optional tag parameters (omit or set to "" to leave unset) ---

variable "owner" {
  description = "Responsible team or owner (e.g., platform-team)"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center or chargeback code (e.g., CC-1234)"
  type        = string
  default     = ""
}

variable "business_unit" {
  description = "Business unit or department (e.g., engineering)"
  type        = string
  default     = ""
}

variable "criticality" {
  description = "Business criticality: low | medium | high | critical"
  type        = string
  default     = ""

  validation {
    condition     = var.criticality == "" || contains(["low", "medium", "high", "critical"], var.criticality)
    error_message = "criticality must be one of: low, medium, high, critical (or empty to omit)."
  }
}

variable "data_classification" {
  description = "Data classification: public | internal | confidential | restricted"
  type        = string
  default     = ""

  validation {
    condition     = var.data_classification == "" || contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted (or empty to omit)."
  }
}

variable "expiry_date" {
  description = "Scheduled decommission date for temporary resources (ISO 8601, e.g., 2026-12-31)"
  type        = string
  default     = ""
}

variable "is_production" {
  description = "Flag to indicate if this is a production environment. When false (demo/dev), resources will be completely purged on destroy for clean teardown. When true (production), resources will be soft-deleted to prevent accidental data loss."
  type        = bool
  default     = false
}
