// _variables.foundry.tf

variable "ai_project_developers_group_name" {
  description = "The name of the Azure AD group for AI Foundry project developers"
  type        = string
}

variable "enable_app_insights" {
  description = "Enable Application Insights for the AI Foundry resources"
  type        = bool
  default     = false
}

variable "cognitive_project_name" {
  description = "Name for the Microsoft Foundry (Cognitive) Project"
  type        = string
}

variable "cognitive_project_description" {
  description = "Description for the Microsoft Foundry (Cognitive) Project"
  type        = string
}

variable "cognitive_account_sku" {
  description = "SKU for the Foundry's Cognitive Account resource"
  type        = string
  default     = "S0"
}

variable "cognitive_deployments" {
  description = "List of cognitive deployments to create in the Foundry's Cognitive Account"
  type = list(object({
    name            = string
    model           = string
    version         = string
    format          = string
    sku             = string
    capacity        = number
    rai_policy_name = optional(string)
  }))
  default = []
}

variable "cognitive_rbac_propagation_wait_duration" {
  description = "Time in seconds to wait for RBAC role assignments to propagate in Azure. RBAC propagation can take several minutes in large Azure environments. Default is 120 seconds for reliable deployments. If you encounter permission errors during deployment, consider increasing this value to 180 or 300 seconds."
  type        = string
  default     = "120s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.cognitive_rbac_propagation_wait_duration))
    error_message = "The wait duration must be specified in seconds with format: <number>s (e.g., '120s')."
  }
}
