# main.tags.tf

# --- Tag construction ---
# Governance tags are always included; optional well-known tags are added when non-empty.
locals {
  governance_tags = {
    environment = var.environment
    workload    = var.workload
    project     = var.project
    location    = var.location
    createdBy   = "terraform"
  }

  optional_tags = merge(
    var.owner != "" ? { owner = var.owner } : {},
    var.cost_center != "" ? { costCenter = var.cost_center } : {},
    var.business_unit != "" ? { businessUnit = var.business_unit } : {},
    var.criticality != "" ? { criticality = var.criticality } : {},
    var.data_classification != "" ? { dataClassification = var.data_classification } : {},
    var.expiry_date != "" ? { expiryDate = var.expiry_date } : {},
  )

  tags = merge(
    local.governance_tags,
    local.optional_tags,
    var.extra_tags
  )
}
