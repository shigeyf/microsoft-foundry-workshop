# main.account.capabilityhost.tf — Account-level Capability Host
#
# Hosted Agents require an account-level capability host.
# This resource type is not supported by the azurerm provider, so azapi is used.
#
# Note: The capabilityHosts API does not support DELETE.
# Remove from state before terraform destroy:
#   terraform state rm 'module.foundry_agents.azapi_resource.account_capability_host[0]'

resource "azapi_resource" "account_capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/capabilityHosts@${local.cognitiveservices_api_version}"
  name      = "accountcaphost"
  parent_id = var.foundry_account_id

  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind             = "Agents"
      enablePublicHostingEnvironment = true
    }
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}
