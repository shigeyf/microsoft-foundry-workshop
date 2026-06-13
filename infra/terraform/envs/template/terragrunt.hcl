# terragrunt.hcl
#
# Example environment variable settings (manage via .envrc or CI/CD secrets):
#   export ARM_TENANT_ID="<tenant-id>"
#   export ARM_SUBSCRIPTION_ID="<subscription-id>"
#   export ARM_BACKEND_RESOURCE_GROUP="<resource-group-name>"
#   export ARM_BACKEND_STORAGE_ACCOUNT="<storage-account-name>"
#
# Optional environment variables (with defaults):
#   export ARM_BACKEND_CONTAINER="tfstate"
#   export ARM_BACKEND_KEY="foundry.terraform.tfstate"
#   export DEPLOYMENT_NAME="basic" (matches subdirectory in infra/terraform/deployments/)
#   export ENABLE_BACKEND_PUBLIC_ACCESS="true" or "false" (default: false)
#
# This configuration assumes the backend storage account has Azure AD
# authentication enabled and public network access disabled.
#

locals {
    arm_tenant_id                = get_env("ARM_TENANT_ID")
    arm_subscription_id          = get_env("ARM_SUBSCRIPTION_ID")
    backend_resource_group       = get_env("ARM_BACKEND_RESOURCE_GROUP")
    backend_storage_account      = get_env("ARM_BACKEND_STORAGE_ACCOUNT")
    backend_container_name       = get_env("ARM_BACKEND_CONTAINER", "tfstate")
    backend_key                  = get_env("ARM_BACKEND_KEY", "foundry.terraform.tfstate")
    deployment_name              = get_env("DEPLOYMENT_NAME", "basic")
    enable_backend_public_access = get_env("ENABLE_BACKEND_PUBLIC_ACCESS", "false")
}

terraform {
    source = "${get_repo_root()}/infra/terraform//deployments/${local.deployment_name}"

    before_hook "pre-validate" {
        commands     = ["init", "plan", "apply", "destroy"]
        execute      = [
            "bash", "-c",
            <<-EOT
            set -euo pipefail
            current_tenant="$(az account show --query tenantId -o tsv 2>/dev/null || true)"
            if [[ "$current_tenant" != "$ARM_TENANT_ID" ]]; then
                az login --tenant "$ARM_TENANT_ID"
            fi
            az account set --subscription $ARM_SUBSCRIPTION_ID
            EOT
        ]
    }

    # Public network access is disabled by default for Backend Storage,
    # so temporarily enable it before init/plan/apply/destroy/import/state.
    # Set ENABLE_BACKEND_PUBLIC_ACCESS="false" to skip this hook.
    before_hook "enable_backend_public_access" {
        commands = ["init", "plan", "apply", "destroy", "import", "refresh", "state"]
        execute  = [
            "bash", "-c",
            <<-EOT
            set -euo pipefail
            if [[ "${local.enable_backend_public_access}" != "true" ]]; then
                echo "Skipping enable_backend_public_access (ENABLE_BACKEND_PUBLIC_ACCESS=${local.enable_backend_public_access})"
                exit 0
            fi
            az storage account update \
                --name ${local.backend_storage_account} \
                --resource-group ${local.backend_resource_group} \
                --public-network-access Enabled \
                --default-action Allow \
                --only-show-errors -o none
            # Wait for propagation (DNS/firewall changes may take tens of seconds)
            for i in {1..12}; do
                if az storage container show \
                        --account-name ${local.backend_storage_account} \
                        --name ${local.backend_container_name} \
                        --auth-mode login -o none 2>/dev/null; then
                    exit 0
                fi
                sleep 5
            done
            echo "Backend storage is still unreachable" >&2
            exit 1
            EOT
        ]
    }

    extra_arguments "common_vars" {
        commands = ["init", "plan", "apply", "destroy", "validate", "import", "refresh", "output", "state", "console"]
        env_vars = {
            ARM_TENANT_ID       = local.arm_tenant_id
            ARM_SUBSCRIPTION_ID = local.arm_subscription_id
        }
    }

    extra_arguments "custom_vars" {
        commands = get_terraform_commands_that_need_vars()
        arguments = [
            "-var-file=${get_terragrunt_dir()}/terraform.tfvars"
        ]
    }

    extra_arguments "parallelism" {
        commands = ["apply", "plan", "destroy"]
        arguments = ["-parallelism=16"]
    }

    extra_arguments "auto_approve" {
        commands = ["apply", "destroy"]
        arguments = ["-auto-approve"]
    }
}

remote_state {
    backend = "azurerm"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        use_azuread_auth     = "true"
        resource_group_name  = local.backend_resource_group
        storage_account_name = local.backend_storage_account
        container_name       = local.backend_container_name
        key                  = local.backend_key
    }
}
