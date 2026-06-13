# variables.foundry.project.tf — Foundry Project parameters

variable "project_name" {
  description = "Name of the Foundry Project"
  type        = string
}

variable "project_display_name" {
  description = "Display name shown in the Foundry portal"
  type        = string
}

variable "project_description" {
  description = "Description of the Foundry Project"
  type        = string
}
