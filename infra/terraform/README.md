# Microsoft Foundry - Terraform Infrastructure as Code

This directory contains the Terraform IaC code for Microsoft Foundry deployment.

## 1. Development Environment

### 1.1. Open in Dev Container

This project supports Dev Containers,
 and the necessary tools are automatically set up.
The Dev Container configuration is located in `.devcontainer/terraform/devcontainer.json`.

> :bulb: **What is a Dev Container?**
>
> A Dev Container (Development Container) is a mechanism that packages
> development environments in a fully reproducible way using Docker containers.
> This allows all team members to easily set up the same development environment,
> avoiding the "it works on my machine" problem.
> For more details, see the [VS Code Dev Containers documentation][devcontainer-docs].
>
> [devcontainer-docs]: https://code.visualstudio.com/docs/devcontainers/containers

#### 1.1.1 Installed Tools

| Tool | Version | Description |
| -------- | ---------- | ------ |
| Terraform | 1.9 | IaC tool. Declaratively define and manage Azure resources |
| TFLint | latest | Static analysis tool for Terraform code |
| Azure CLI | latest | Tool to manage Azure resources from CLI |
| Git & Zsh | - | Version control and shell environment |
| Docker-in-Docker | latest | Feature that enables Docker usage within containers |
| Node.js | LTS | JavaScript runtime |

#### 1.1.2 Usage

**Prerequisites:**

- [Docker Desktop][docker-desktop] is installed and running
- [Dev Containers extension][devcontainers-ext] is installed in VS Code

[docker-desktop]: https://www.docker.com/products/docker-desktop/
[devcontainers-ext]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

**Open in Dev Container (Terraform execution / full development):**

1. In VS Code, select **File > Open Folder**
2. Open the repository root folder
3. Press Ctrl+Shift+P → Select "**Dev Containers: Reopen in Container**"
4. Select the `Terraform Development` container
5. The necessary tools will be automatically
  set up (may take a few minutes on first run)

> :hourglass_flowing_sand: **Note on First Launch**
>
> The first launch may take 5-10 minutes
> as the container image is downloaded and built.
> Subsequent launches will use the cache and start faster.

### 1.2. Open in Regular VS Code Environment

A VS Code Workspace file is provided for this project,
 which works in a regular VS Code environment (without Dev Container).
VS Code's workspace feature is useful for browsing across multiple projects.
For Terraform execution, you need to manually install the tools.

#### 1.2.1 Recommended Tools to Install

If not using Dev Container, please manually install the following tools:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.9
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [TFLint](https://github.com/terraform-linters/tflint)

Recommended VS Code extensions (auto-recommended in .vscode/extensions.json):

- HashiCorp Terraform
- Azure Terraform
- Azure CLI Tools
- YAML

#### 1.2.2 Usage

**Open with VS Code Workspace file (code browsing / minor edits):**

1. Open `project-infra.code-workspace` at the repository root
2. Select `Foundry (Terraform IaC)`

## 2. Project Structure

```text
basic/
├── main.*.tf          - Resource definitions (rg, keyvault, cognitive, search, vnet, etc.)
├── _variables.*.tf    - Variable definitions (foundry, keyvault, search, vnet)
├── _locals.*.tf       - Local variables (naming conventions)
├── data.tf            - Data source definitions
├── backend.tf         - Backend configuration for state management
├── providers.tf       - Provider configuration
└── terraform.tf       - Terraform version configuration
```

## 3. Deploying Resources to Azure with IaC

### 3.1. Azure Login Authentication

By default, Terraform execution uses the authenticated context from Azure CLI login.

Please log in with the following command:

```bash
az login --tenant <tenant-id>
```

> :key: **About `<tenant-id>`**
>
> `<tenant-id>` is the Azure Active Directory (Entra ID) tenant identifier.
> If you don't know your tenant ID, check with your administrator or
> find it in [Azure Portal](https://portal.azure.com)
> under "Microsoft Entra ID" → "Overview".

After logging in, verify that the correct subscription is selected:

```bash
# Display current account information
az account show

# Display subscription list
az account list --output table

# Switch subscription if needed
az account set --subscription <subscription-id or name>
```

When using Dev Container,
 the host machine's `~/.azure` folder is automatically mounted,
inheriting the Azure CLI login authentication context from previous executions.

### 3.2 Select IaC Module to Deploy

Select the module to deploy Microsoft Foundry.
Currently, the following modules are available:

- [Basic](./basic/)

```bash
cd <project-root>/infra/terraform/basic
```

### 3.3 Environment Type Configuration (Production vs Demo)

You can specify whether the deployment is for a production or demo environment.
This setting changes the behavior when deleting resources.

#### For Demo/Development Environment (Default)

By default, `is_production = false`, which results in the following behavior:

- **Key Vault**: Completely deleted (purged)
  when running `terraform destroy`,
  allowing immediate recreation with the same name
- **Resource Group**: Can be deleted even if it contains resources

This allows for complete cleanup after finishing with the demo environment.

```bash
# No configuration needed when using default values
terraform apply
```

#### For Production Environment

For production environments,
 set `is_production = true` to protect data from accidental deletion:

- **Key Vault**: Soft-deleted when running `terraform destroy`,
  recoverable during the retention period
- **Resource Group**: Deletion is prevented if it contains resources

```bash
# Create terraform.tfvars file
echo 'is_production = true' > terraform.tfvars

# Or specify on command line
terraform apply -var="is_production=true"
```

> :warning: **Important**
>
> Always set `is_production = true` for production environments.
> This allows data recovery even if Key Vault is accidentally deleted.

### 3.4 Prepare Backend Configuration

Prepare the Azure Storage account configuration for storing Terraform state files.
Copy the sample file and modify the contents.

```bash
cp ../backend.hcl.example backend.hcl
```

> :information_source: **backend.hcl configuration example**
>
> ```hcl
> storage_account_name = "<your-tfstate-storage-account>"
> container_name       = "tfstate"
> key                  = "basic-setup.terraform.tfstate"
> ```
>
> Optionally, you can also specify `resource_group_name` and `subscription_id`
> if the storage account is in a different subscription.

### 3.5. Initialization

```bash
terraform init -backend-config=backend.hcl
```

> :information_source: **What is `terraform init`?**
>
> This command initializes the Terraform project.
> The following processes are performed:
>
> - Download required Provider plugins
> - Configure backend (state file storage location)
> - Initialize modules
>
> Required when running for the first time in a new environment or
> when changing Provider versions.

### 3.6. Pre-deployment Verification

```bash
terraform plan
```

> :mag: **What is `terraform plan`?**
>
> This command previews what will be created, changed, or deleted
> without actually modifying resources.
> How to read the output:
>
> - `+ create` : Resources to be newly created (green)
> - `~ update in-place` : Resources to be modified (yellow)
> - `- destroy` : Resources to be deleted (red)
>
> **Always verify changes with `plan` before running `apply`.**

### 3.7. Deployment

```bash
terraform apply
```

When executed, the changes will be displayed
 and a confirmation prompt will appear.
 Type `yes` and press Enter to start the deployment.

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

> :warning: **Note**
>
> Deployment may take several minutes to tens of minutes. Do not interrupt the process.
> Interruption may cause resource state inconsistencies.

### 3.8. Delete Deployed Resources

```bash
terraform apply -destroy
```

Alternatively, the following shortcut command produces the same result:

```bash
terraform destroy
```

> :rotating_light: **Important Warning**
>
> This command **completely deletes** all resources managed by Terraform.
>
> - Deleted resources cannot be restored
> - Database data will also be lost
> - Exercise extreme caution in production environments
>
> Always verify deletion targets with `terraform plan -destroy` before deletion.

## 4. Code Quality Checks

When executing commit commands to the repository, checks described in this section
 are performed on staged files before
 the commit operation using the `pre-commit` tool.
To manually run the `pre-commit` tool, execute the following command:

```bash
pre-commit run
```

### Terraform File Format Check

```bash
terraform fmt -recursive
```

### Terraform Module Validation Check

```bash
terraform validate
```

### Linting with TFLint

```bash
tflint
```

## 5. Troubleshooting

### Dev Container Won't Start

**Possible causes and solutions:**

| Cause | Solution |
| ---- | ------ |
| Docker Desktop is stopped | Start Docker Desktop and wait until the status bar turns green |
| Docker not installed in WSL | Run `docker --version` in WSL to verify |
| Dev Containers extension missing | Install from VS Code extensions |
| Cache issues | Run "Dev Containers: Rebuild Container" |

### Azure Authentication Error Occurs

**Error example:**
 `Error: AADSTS700016: Application with identifier '...' was not found`

```bash
# Clear current authentication state
az logout

# Log in again
az login --tenant <tenant-id>

# Verify authentication state
az account show
```

### Terraform State File Lock Error

**Error example:** `Error: Error acquiring the state lock`

This occurs when the previous execution did not terminate normally.

```bash
# Force unlock (verify no one else is using it before executing)
terraform force-unlock <LOCK_ID>
```

### Provider Version Error

**Error example:** `Error: Incompatible provider version`

```bash
# Clear provider cache and reinitialize
rm -rf .terraform
terraform init -backend-config=backend.hcl -upgrade
```

## 6. Glossary

For beginners, here are explanations of the main terms used in this document.

| Term | Description |
| ---- | ---- |
| **Terraform** | IaC tool developed by HashiCorp |
| **IaC** | Methodology for managing infrastructure as code |
| **Provider** | Plugin that enables Terraform to interact with cloud services |
| **State** | File that stores the current state of resources |
| **Backend** | Storage location for state files. Team uses Azure Storage |
| **Module** | Reusable unit of Terraform code |
| **Plan** | Operation to preview changes |
| **Apply** | Operation to apply planned changes |

## 7. Reference Links

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [TFLint Rules](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [Terraform Official Tutorial](https://developer.hashicorp.com/terraform/tutorials)
- [Azure Documentation for Beginners](https://learn.microsoft.com/en-us/azure/)
