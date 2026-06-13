# variables.foundry.connections.tf — Connection parameters

variable "enable_app_insights_connection" {
  description = "Whether to create the Application Insights connection on the Foundry Account. Must be a value known at plan time (e.g., an input variable)."
  type        = bool
  default     = false
}

variable "app_insights_id" {
  description = "Resource ID of the Application Insights. Non-empty value enables connection creation."
  type        = string
  default     = ""
}

variable "app_insights_name" {
  description = "Name of the Application Insights (used for Connection naming)"
  type        = string
  default     = ""
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string (empty string to skip connection)"
  type        = string
  default     = ""
  sensitive   = true
}
