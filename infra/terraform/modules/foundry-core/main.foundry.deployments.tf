# main.foundry.deployments.tf — Foundry Model Deployments

resource "azurerm_cognitive_deployment" "models" {
  for_each             = { for d in var.model_deployments : d.name => d }
  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.this.id
  rai_policy_name      = each.value.rai_policy_name

  model {
    format  = each.value.format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}
