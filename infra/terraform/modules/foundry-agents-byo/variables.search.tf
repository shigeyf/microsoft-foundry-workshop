# variables.search.tf

variable "vector_store_account_name" {
  description = "Name of the Vector Store AI Search account for BYO Agent Service"
  type        = string
}

# variable "enable_vector_store_sensitivity_labels" {
#   description = "Enable sensitivity labels for Vector Store AI Search indexing"
#   type        = bool
#   default     = false
# }

variable "vector_store_sku" {
  description = "SKU for the Vector Store AI Search resource"
  type        = string
  default     = "standard"
}

variable "vector_store_replica_count" {
  type        = number
  description = "Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier)."
  default     = 1
  validation {
    condition     = var.vector_store_replica_count >= 1 && var.vector_store_replica_count <= 12
    error_message = "The vector_store_replica_count must be between 1 and 12."
  }
}

variable "vector_store_partition_count" {
  type        = number
  description = "Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units."
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.vector_store_partition_count)
    error_message = "The vector_store_partition_count must be one of the following values: 1, 2, 3, 4, 6, 12."
  }
}

variable "vector_store_semantic_search_sku" {
  description = "SKU for the Vector Store AI Semantic Search resource"
  type        = string
  default     = ""
}
