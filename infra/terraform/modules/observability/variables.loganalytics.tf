# variables.loganalytics.tf — Log Analytics Workspace parameters

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}

variable "existing_log_workspace_id" {
  description = "Resource ID of an existing Log Analytics Workspace (required when use_existing=true)"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "Log Analytics data retention in days (only effective when use_existing=false)"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_in_days >= 30 && var.log_retention_in_days <= 730
    error_message = "log_retention_in_days must be between 30 and 730."
  }
}
