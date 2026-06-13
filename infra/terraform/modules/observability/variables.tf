# variables.tf — observability module common parameters

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "use_existing" {
  description = <<-EOT
    false (default) — Create new Log Analytics and Application Insights resources.
    true            — Reference existing resources. Requires existing_* parameters.
  EOT
  type        = bool
  default     = false
}
