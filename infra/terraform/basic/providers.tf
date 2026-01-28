// providers.tf

provider "azurerm" {
  storage_use_azuread = true
  subscription_id     = var.target_subscription_id == "" ? null : var.target_subscription_id
  features {
    resource_group {
      # For demo/dev environments, allow deletion even with resources inside
      # For production, prevent accidental deletion of resource groups with resources
      prevent_deletion_if_contains_resources = var.is_production
    }
    key_vault {
      # For demo/dev environments, purge soft-deleted items on destroy for clean teardown
      # For production, keep soft-delete protection to prevent accidental data loss
      purge_soft_delete_on_destroy = !var.is_production
    }
  }
}

// Provider for Connectivity subscription (existing Private DNS Zones)
provider "azurerm" {
  alias               = "connectivity"
  storage_use_azuread = true
  subscription_id = (
    var.connectivity_subscription_id == ""
    ? (var.target_subscription_id == "" ? null : var.target_subscription_id)
    : var.connectivity_subscription_id
  )
  features {}
}

provider "azapi" {
  subscription_id = var.target_subscription_id == "" ? null : var.target_subscription_id
}
