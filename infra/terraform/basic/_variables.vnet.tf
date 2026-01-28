// _variables.vnet.tf

variable "network_isolation_mode" {
  description = <<-EOT
    Network isolation mode:
    - "public"  : Public access only (no VNet/PE)
    - "hybrid"  : VNet/PE created + public access enabled (for deployment Phase 1)
    - "private" : VNet/PE created + public access disabled (for production, deployment Phase 2)
  EOT
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "hybrid", "private"], var.network_isolation_mode)
    error_message = "network_isolation_mode must be one of 'public', 'hybrid', or 'private'"
  }
}

variable "vnet_address_space" {
  description = "The address space of the virtual network"
  type        = string
  default     = "192.168.0.0/16"
}

variable "private_endpoint_subnet_address_prefix" {
  description = "The address prefix for the private endpoint subnet"
  type        = string
  default     = "192.168.1.0/24"
}

// ============================================================================
// Existing Private DNS Zone Configuration
// ============================================================================

variable "use_existing_private_dns_zones" {
  description = <<-EOT
    Use existing Private DNS Zones from a Connectivity subscription instead of creating new ones.
    When true, connectivity_subscription_id and connectivity_dns_zone_resource_group are required.
  EOT
  type        = bool
  default     = false
}

variable "connectivity_subscription_id" {
  description = "The subscription ID where the existing Private DNS Zones are located (Connectivity subscription)"
  type        = string
  default     = ""

  validation {
    condition     = var.connectivity_subscription_id == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.connectivity_subscription_id))
    error_message = "connectivity_subscription_id must be a valid GUID format or empty string"
  }
}

variable "connectivity_dns_zone_resource_group" {
  description = "The resource group name where the existing Private DNS Zones are located"
  type        = string
  default     = ""
}
