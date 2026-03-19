// _variables.acr.tf

variable "acr_sku" {
  description = "The SKU of the Azure Container Registry. Allowed values are 'Basic', 'Standard', and 'Premium'."
  type        = string
  default     = "Basic"
}
