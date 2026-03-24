# Microsoft Foundry - Bicep Infrastructure as Code

This directory contains the Bicep IaC code for Microsoft Foundry deployment.

## 1. Development Environment

### 1.1. Open in Dev Container

This project supports Dev Containers,
and the necessary tools are automatically set up.
The Dev Container configuration is located in `.devcontainer/devcontainer.json`.

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

| Tool             | Version | Description                                               |
| ---------------- | ------- | --------------------------------------------------------- |
| Python           | 3.12    | Programming language runtime                              |
| uv               | latest  | Python package manager                                    |
| Terraform        | 1.9     | IaC tool. Declaratively define and manage Azure resources |
| TFLint           | latest  | Static analysis tool for Terraform code                   |
| Azure CLI        | latest  | Tool to manage Azure resources from CLI                   |
| Git & Zsh        | -       | Version control and shell environment                     |
| Docker-in-Docker | latest  | Feature that enables Docker usage within containers       |
| Node.js          | LTS     | JavaScript runtime                                        |

> :information_source: **About the Bicep CLI**
>
> The Bicep CLI is included with Azure CLI. No separate installation is needed.
> You can verify with `az bicep version`.

#### 1.1.2 Usage

**Prerequisites:**

- [Docker Desktop][docker-desktop] is installed and running
- [Dev Containers extension][devcontainers-ext] is installed in VS Code

[docker-desktop]: https://www.docker.com/products/docker-desktop/
[devcontainers-ext]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

**Open in Dev Container (Bicep execution / full development):**

1. In VS Code, select **File > Open Folder**
2. Open the repository root folder
3. Press Ctrl+Shift+P → Select "**Dev Containers: Reopen in Container**"
4. Select the `Microsoft Foundry Workshop` container
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
For Bicep execution, you need to manually install the tools.

#### 1.2.1 Recommended Tools to Install

If not using Dev Container, please manually install the following tools:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (includes Bicep CLI)
- [Bicep VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

Recommended VS Code extensions (auto-recommended in .vscode/extensions.json):

- Bicep
- Azure CLI Tools
- YAML

#### 1.2.2 Usage

**Open with VS Code Workspace file (code browsing / minor edits):**

1. Open `project-infra.code-workspace` at the repository root
2. Select `Foundry (Bicep IaC)`

## 2. Project Structure

```text
bicep/
├── bicepconfig.json           - Bicep linter and formatting configuration
├── basic/
│   ├── main.bicep             - Main deployment template (resource group scope)
│   ├── main.bicepparam        - Environment-specific parameter values
│   ├── main.bicepparam.example - Parameter file template
│   ├── deploy.sh              - Smart deployment wrapper script
│   └── modules/
│       ├── naming.bicep               - CAF-compliant naming functions
│       ├── types.bicep                - Shared type definitions (CommonTags, ModelDeploymentConfig, etc.)
│       ├── regions.bicep              - Azure region abbreviation map
│       ├── roleDefinitions.bicep      - RBAC role ID definitions
│       ├── foundry.bicep              - Foundry Account + Project + AI Search Connection
│       ├── foundry.deployments.bicep  - OpenAI model deployments
│       ├── search.bicep               - Azure AI Search service
│       ├── storage.bicep              - Blob Storage account
│       ├── acr.bicep                  - Container Registry (with CMK support)
│       ├── keyvault.bicep             - Key Vault (RBAC mode)
│       ├── keyvault.key.bicep         - CMK encryption key with rotation
│       ├── identity.cmk.bicep         - User Assigned Managed Identity for CMK
│       ├── observability.bicep        - Log Analytics + Application Insights
│       ├── rbac.services.bicep        - Service-to-service RBAC assignments
│       ├── rbac.cmk.bicep             - CMK encryption RBAC
│       ├── rbac.users.bicep           - User/group RBAC assignments
│       ├── vnet.bicep                 - Virtual Network + PE subnet
│       ├── private-dns-zone.bicep     - Private DNS zones + VNet links
│       ├── private-endpoint.bicep     - Generic private endpoint module
│       └── azuread-mip-mrms.bicep     - MIP/MRMS app role for AI Search sensitivity labels
```

## 3. Deploying Resources to Azure with IaC

### 3.1. Azure Login Authentication

By default, Bicep deployment uses the authenticated context from Azure CLI login.

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
cd <project-root>/infra/bicep/basic
```

### 3.3 Prepare Parameter File

Copy the example parameter file and modify the contents.

```bash
cp main.bicepparam.example main.bicepparam
```

Edit `main.bicepparam` to set the required parameters:

```bicep
using './main.bicep'

// Required parameters
param env = 'poc'                                          // dev | stg | poc | prd
param project = 'foundry'                                  // Project abbreviation (8 chars or less)
param foundryProjectDisplayName = 'Foundry PoC'            // Display name in Foundry portal
param foundryProjectDescription = 'Foundry PoC project'    // Project description
param location = 'eastus2'                                 // Azure region

// Optional: Observability
param createObservability = true

// Optional: Model deployments
param modelDeployments = [
  {
    name: 'gpt-4.1'
    modelName: 'gpt-4.1'
    modelVersion: '2025-04-14'
    skuName: 'GlobalStandard'
    capacity: 100
  }
]

// Optional: AI Search
param enableAiSearch = true

// Optional: Customer Managed Key encryption
param enableCmk = true
param enableCmkAutoRotation = true
```

### 3.4 Deploy with the Deployment Script (Recommended)

The `deploy.sh` script provides a smart deployment wrapper that
automatically detects and handles soft-deleted resources.

```bash
export RG="<resource-group-name>"
export deployerObjectId="<your-entra-object-id>"
export LOCATION="eastus2"

# Optional: Azure AD group IDs
export aiDeveloperGroupId="<developer-group-object-id>"
export aiUserGroupId="<user-group-object-id>"

bash deploy.sh
```

The script performs the following 3-step process:

1. **Name Resolution**: Runs `az deployment group what-if` to resolve resource names
   (including `uniqueString()` hash) from the Bicep template
2. **Soft-Delete Detection**: Checks for soft-deleted Key Vault and Cognitive Services
   that would conflict with the deployment, and automatically sets restore flags
3. **Deployment**: Executes `az deployment group create` with any necessary restore parameters

> :information_source: **About Environment Variables**
>
> | Variable             | Required | Description                                               |
> | -------------------- | -------- | --------------------------------------------------------- |
> | `RG`                 | Yes      | Target resource group name                                |
> | `deployerObjectId`   | Yes      | Entra ID Object ID of the deployer (for RBAC assignments) |
> | `LOCATION`           | Yes      | Azure region for soft-delete lookup                       |
> | `aiDeveloperGroupId` | No       | Entra ID Object ID of the AI Developer group              |
> | `aiUserGroupId`      | No       | Entra ID Object ID of the AI User group (read-only)       |
> | `DEPLOYMENT_NAME`    | No       | Deployment name prefix (auto-generated if omitted)        |

### 3.5 Deploy Manually with Azure CLI

If you prefer to deploy manually without the wrapper script:

```bash
# Pre-deployment verification
az deployment group what-if \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="<your-entra-object-id>"

# Deploy
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="<your-entra-object-id>"
```

> :warning: **Note**
>
> Deployment may take several minutes to tens of minutes. Do not interrupt the process.
> Interruption may cause resource state inconsistencies.

### 3.6 Handling Soft-Deleted Resources

When re-deploying after a previous deletion, Azure may keep resources in a soft-deleted state.
If you encounter errors related to existing soft-deleted resources,
add the restore parameters:

```bash
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="<your-entra-object-id>" \
  --parameters keyvaultRestore=true \
  --parameters foundryRestore=true
```

> :bulb: **Tip**
>
> The `deploy.sh` script automatically detects soft-deleted resources
> and sets these parameters, so manual intervention is usually not needed.

### 3.7. Delete Deployed Resources

```bash
az group delete --name $RG
```

> :rotating_light: **Important Warning**
>
> This command **completely deletes** the resource group and all resources within it.
>
> - Deleted resources cannot be restored (except soft-deleted Key Vault and Cognitive Services)
> - Exercise extreme caution in production environments
>
> For a selective cleanup, delete individual resources first via Azure Portal or CLI.

## 4. Code Quality Checks

### Bicep Linter

The `bicepconfig.json` enforces security and quality rules:

| Rule                                  | Level   | Description                          |
| ------------------------------------- | ------- | ------------------------------------ |
| `adminusername-should-not-be-literal` | error   | Prevent hardcoded admin usernames    |
| `no-hardcoded-env-urls`               | error   | No hardcoded Azure environment URLs  |
| `no-hardcoded-location`               | error   | Location must be parameterized       |
| `secure-parameter-default`            | error   | Secure params must not have defaults |
| `no-unused-params`                    | warning | Detect unused parameters             |
| `use-recent-api-versions`             | warning | Prefer recent API versions           |

The linter runs automatically in VS Code with the Bicep extension.
To check from the CLI:

```bash
az bicep build --file basic/main.bicep
```

### Pre-commit Checks

When executing commit commands to the repository, checks are performed
on staged files before the commit operation using the `pre-commit` tool.

```bash
pre-commit run
```

## 5. Troubleshooting

### Dev Container Won't Start

**Possible causes and solutions:**

| Cause                            | Solution                                                       |
| -------------------------------- | -------------------------------------------------------------- |
| Docker Desktop is stopped        | Start Docker Desktop and wait until the status bar turns green |
| Docker not installed in WSL      | Run `docker --version` in WSL to verify                        |
| Dev Containers extension missing | Install from VS Code extensions                                |
| Cache issues                     | Run "Dev Containers: Rebuild Container"                        |

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

### Soft-Deleted Resource Conflict

**Error example:** `A vault with the same name already exists in deleted state`

This occurs when a resource with the same name was previously deleted
but remains in soft-deleted state.

```bash
# Option 1: Use deploy.sh (recommended, auto-detects)
bash deploy.sh

# Option 2: Add restore parameters manually
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="..." \
  --parameters keyvaultRestore=true \
  --parameters foundryRestore=true

# Option 3: Purge the soft-deleted resources manually
az keyvault purge --name <vault-name> --location <location>
az cognitiveservices account purge --name <account-name> --resource-group <rg> --location <location>
```

### Bicep Compilation Error

**Error example:** `Error BCP0xx: ...`

```bash
# Verify Bicep CLI version
az bicep version

# Upgrade Bicep CLI
az bicep upgrade

# Validate the template
az bicep build --file basic/main.bicep
```

## 6. Glossary

For beginners, here are explanations of the main terms used in this document.

| Term            | Description                                                                   |
| --------------- | ----------------------------------------------------------------------------- |
| **Bicep**       | Domain-specific language for deploying Azure resources declaratively          |
| **IaC**         | Methodology for managing infrastructure as code                               |
| **ARM**         | Azure Resource Manager — the underlying deployment engine for Bicep           |
| **Module**      | Reusable Bicep file that encapsulates a set of resources                      |
| **Parameter**   | Input value that customizes deployment behavior                               |
| **What-If**     | Operation to preview changes without actually deploying                       |
| **CMK**         | Customer Managed Key — encryption using your own Key Vault keys               |
| **RBAC**        | Role-Based Access Control — Azure's authorization mechanism                   |
| **Soft Delete** | Feature that retains deleted resources for recovery during a retention period |

## 7. Reference Links

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Bicep Linter Rules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Azure Cognitive Services REST API](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/)
- [Azure Documentation for Beginners](https://learn.microsoft.com/en-us/azure/)
