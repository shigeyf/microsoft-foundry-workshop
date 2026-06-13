# variables.foundry.deployments.tf — Model Deployment parameters

variable "model_deployments" {
  description = "List of models to deploy"
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
