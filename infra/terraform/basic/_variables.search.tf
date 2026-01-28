// _variables.search.tf

variable "enable_ai_search" {
  description = "Enable AI Search for the AI Foundry resources"
  type        = bool
  default     = false
}

variable "ai_search_sku" {
  description = "SKU for the AI Search resource"
  type        = string
  default     = "standard"
}

variable "ai_search_replica_count" {
  type        = number
  description = "Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier)."
  default     = 1
  validation {
    condition     = var.ai_search_replica_count >= 1 && var.ai_search_replica_count <= 12
    error_message = "The ai_search_replica_count must be between 1 and 12."
  }
}

variable "ai_search_partition_count" {
  type        = number
  description = "Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units."
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.ai_search_partition_count)
    error_message = "The ai_search_partition_count must be one of the following values: 1, 2, 3, 4, 6, 12."
  }
}

variable "ai_semantic_search_sku" {
  description = "SKU for the AI Semantic Search resource"
  type        = string
  default     = "standard"
}
