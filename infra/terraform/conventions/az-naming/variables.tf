# variables.tf

# === Required inputs ===

variable "subscription_id" {
  description = "Azure Subscription ID (used as unique_string seed for global uniqueness)"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid GUID."
  }
}

variable "workload" {
  description = "Workload or service name (e.g., \"foundry\")"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "workload must be lowercase alphanumeric only."
  }
}

variable "project" {
  description = "Project or sub-workload name (e.g., \"aipoc\")"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project))
    error_message = "project must be lowercase alphanumeric only."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod", "test", "sandbox"], var.environment)
    error_message = "environment must be one of: dev, stg, prod, test, sandbox."
  }
}

variable "location" {
  description = "Azure region name (e.g., eastus, japaneast)"
  type        = string
}

# === Optional inputs (naming control) ===

variable "random_length" {
  description = "Length of the random string for additional uniqueness"
  type        = number
  default     = 4
}

variable "use_hash_for_rg" {
  description = "Whether to append a hash suffix to the resource group name"
  type        = bool
  default     = false
}

variable "instance_number" {
  description = "Instance number for sequential naming (zero-padded)"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_number >= 1 && var.instance_number <= 9999
    error_message = "instance_number must be between 1 and 9999."
  }
}

variable "instance_padding" {
  description = "Number of digits for zero-padded instance number (hash length = 20 - instance_padding)"
  type        = number
  default     = 4

  validation {
    condition     = var.instance_padding >= 2 && var.instance_padding <= 6
    error_message = "instance_padding must be between 2 and 6."
  }
}

# === Optional inputs (tags) ===

variable "extra_tags" {
  description = "Additional freeform tags to merge into the output tags"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Responsible team or owner (e.g., platform-team). Empty to omit."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center or chargeback code (e.g., CC-1234). Empty to omit."
  type        = string
  default     = ""
}

variable "business_unit" {
  description = "Business unit or department (e.g., engineering). Empty to omit."
  type        = string
  default     = ""
}

variable "criticality" {
  description = "Business criticality: low | medium | high | critical. Empty to omit."
  type        = string
  default     = ""

  validation {
    condition     = var.criticality == "" || contains(["low", "medium", "high", "critical"], var.criticality)
    error_message = "criticality must be one of: low, medium, high, critical (or empty to omit)."
  }
}

variable "data_classification" {
  description = "Data classification: public | internal | confidential | restricted. Empty to omit."
  type        = string
  default     = ""

  validation {
    condition     = var.data_classification == "" || contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted (or empty to omit)."
  }
}

variable "expiry_date" {
  description = "Scheduled decommission date for temporary resources (ISO 8601, e.g., 2026-12-31). Empty to omit."
  type        = string
  default     = ""
}
