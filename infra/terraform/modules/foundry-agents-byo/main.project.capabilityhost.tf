# main.project.capabilityhost.tf — Project-level Capability Host

resource "azapi_resource" "project_capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@${local.cognitiveservices_api_version}"
  name      = "projectcaphost"
  parent_id = var.foundry_project_id

  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      storageConnections       = [local.storage_connection_name]
      vectorStoreConnections   = [local.vector_store_connection_name]
      threadStorageConnections = [local.thread_storage_connection_name]
    }
  }

  depends_on = [
    azapi_resource.account_capability_host,
    azapi_resource.file_storage_connection,
    azapi_resource.vector_store_connection,
    azapi_resource.thread_storage_connection,
  ]

  timeouts {
    create = "60m"
    delete = "60m"
  }
}
