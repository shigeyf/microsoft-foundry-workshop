# variables.tf

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

variable "workload" {
  description = "Workload or service name (e.g., \"foundry\")"
  type        = string
  default     = "foundry"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.workload))
    error_message = "workload must be lowercase alphanumeric only."
  }
}

variable "project" {
  description = "Project or sub-workload name (e.g., \"aipoc\")"
  type        = string
  default     = "poc"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project))
    error_message = "project must be lowercase alphanumeric only."
  }
}

variable "env" {
  description = "Environment tag value for the deployed resources"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.env))
    error_message = "env must be lowercase alphanumeric only."
  }
}

variable "location" {
  description = "Azure region for the deployment"
  type        = string
}

variable "use_hash_for_resource_group" {
  description = "Whether to use a hash suffix for the resource group name to ensure uniqueness (recommended for non-production environments). If false, resource group name will be deterministic based on naming convention, which may cause conflicts if deploying multiple instances of this module with the same parameters."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the deployment"
  type        = map(string)
  default     = {}
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

# --- Foundry Project ---

variable "foundry_project_display_name" {
  description = "Display name shown in the Foundry portal"
  type        = string
  default     = "Default Foundry Project"
}

variable "foundry_project_description" {
  description = "Description of the Foundry Project"
  type        = string
  default     = "Default Foundry Project"
}

# --- Model Deployments ---

variable "model_deployments" {
  description = "List of models to deploy to Foundry (provisioned sequentially)"
  type = list(object({
    name            = string
    model_name      = string
    model_version   = string
    format          = optional(string, "OpenAI")
    sku_name        = string
    capacity        = number
    rai_policy_name = optional(string)
  }))
  default = []
}

# --- Observability ---

variable "enable_observability" {
  description = "Whether to enable observability (Log Analytics + Application Insights) for the Foundry resources"
  type        = bool
  default     = true
}

variable "create_observability" {
  description = "Whether to create new Log Analytics / App Insights resources (false = reference existing). Only effective when enable_observability = true."
  type        = bool
  default     = true
}

variable "existing_log_workspace_id" {
  description = "Resource ID of existing Log Analytics workspace (required when enable_observability=true and create_observability=false)"
  type        = string
  default     = ""
}

variable "existing_app_insights_id" {
  description = "Resource ID of existing Application Insights (required when enable_observability=true and create_observability=false)"
  type        = string
  default     = ""
}

# --- BYO Key Vault ---

variable "enable_byo_keyvault" {
  description = "Whether to create a BYO Key Vault connection on the Foundry Account"
  type        = bool
  default     = false
}

# --- RBAC ---

variable "deployer_object_id" {
  description = "Entra ID object ID of the deployer user (empty string to skip)"
  type        = string
  default     = ""
}

variable "deployer_use_foundry_owner" {
  description = "If true, assign Foundry Owner (full access incl. data plane) to deployer instead of Foundry Account Owner (control plane only)"
  type        = bool
  default     = false
}

variable "foundry_developers_group_name" {
  description = "Display name of the Entra ID group for Foundry Developers — assigned Foundry Project Manager role (empty string to skip)"
  type        = string
  default     = ""
}

variable "foundry_users_group_name" {
  description = "Display name of the Entra ID group for Foundry Users — assigned Reader on account + Foundry User on project (empty string to skip)"
  type        = string
  default     = ""
}
