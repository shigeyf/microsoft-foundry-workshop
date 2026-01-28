// main.cognitive.cmk.tf
//
// NOTE:
// Customer-managed key (CMK) support for the cognitive account is implemented
// inline in main.cognitive.tf via the `customer_managed_key` block on
// `azurerm_cognitive_account.this`.
//
// The standalone `azurerm_cognitive_account_customer_managed_key` resource is
// intentionally not used here because it conflicts with the project
// management feature for this deployment. This file is retained only to
// document that design decision and therefore does not define any active
// Terraform resources.
