# _variables.foundry.byo.tf

variable "enable_standard_setup" {
  description = "Enable standard setup for customer BYO resources in Microsoft Foundry (includes Azure Cosmos DB, Azure AI Search, and Storage Account)"
  type        = bool
  default     = false
}

variable "byo_blob_replication_type" {
  description = "Replication type for the BYO Storage Account. Required if enable_standard_setup is true."
  type        = string
  default     = "LRS"
}

variable "byo_ai_search_sku" {
  description = "SKU for the AI Search resource"
  type        = string
  default     = "free"
}

variable "byo_ai_search_replica_count" {
  type        = number
  description = "Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier)."
  default     = 1
  validation {
    condition     = var.byo_ai_search_replica_count >= 1 && var.byo_ai_search_replica_count <= 12
    error_message = "The byo_ai_search_replica_count must be between 1 and 12."
  }
}

variable "byo_ai_search_partition_count" {
  type        = number
  description = "Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units."
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.byo_ai_search_partition_count)
    error_message = "The byo_ai_search_partition_count must be one of the following values: 1, 2, 3, 4, 6, 12."
  }
}

variable "byo_ai_semantic_search_sku" {
  description = "SKU for the AI Semantic Search resource"
  type        = string
  default     = ""
}
