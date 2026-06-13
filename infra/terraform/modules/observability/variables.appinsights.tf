# variables.appinsights.tf — Application Insights parameters

variable "application_insights_name" {
  description = "Name of the Application Insights resource"
  type        = string
}

variable "existing_app_insights_id" {
  description = "Resource ID of an existing Application Insights (required when use_existing=true)"
  type        = string
  default     = ""
}
