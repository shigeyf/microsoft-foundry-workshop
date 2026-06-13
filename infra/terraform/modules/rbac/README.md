# RBAC Module

This module manages Azure Role-Based Access Control (RBAC) role assignments for Microsoft Foundry resources.

## Overview

This module assigns built-in Azure roles to user principals and security groups on Foundry Account and Foundry Project scopes.

## Foundry Built-in Roles (Latest)

> **Important**: The Foundry RBAC roles were recently renamed. The role IDs and core permissions are unchanged. During the rename rollout, Microsoft recommends using **role definition IDs (GUIDs)** instead of role names in code.

| Previous Name            | New Name                    | GUID                                   |
| ------------------------ | --------------------------- | -------------------------------------- |
| Azure AI User            | **Foundry User**            | `53ca6127-db72-4b80-b1b0-d745d6d5456d` |
| Azure AI Owner           | **Foundry Owner**           | `c883944f-8b7b-4483-af10-35834be79c4a` |
| Azure AI Account Owner   | **Foundry Account Owner**   | `e47c6f54-e4a2-4754-9501-8e0985b135e1` |
| Azure AI Project Manager | **Foundry Project Manager** | `eadc314b-1a2d-4efa-be10-5d325db5065e` |

### Role Descriptions

| Role                        | Description                                                                                                                      |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Foundry User**            | Grants reader access to Foundry projects and accounts, plus data actions for Foundry projects. Least-privilege access role.      |
| **Foundry Project Manager** | Lets you perform management and developer actions on Foundry projects. Can conditionally assign the Foundry User role to others. |
| **Foundry Account Owner**   | Grants full access to manage projects and accounts. Can conditionally assign Foundry User, ACR, and monitoring roles.            |
| **Foundry Owner**           | Grants full access to manage and develop within projects and accounts. Highly privileged self-serve role.                        |

### Permissions Matrix

| Capability                             | Foundry User | Foundry Project Manager |     Foundry Account Owner     |         Foundry Owner         |
| -------------------------------------- | :----------: | :---------------------: | :---------------------------: | :---------------------------: |
| Read Foundry resource                  |      ✔       |            ✔            |               ✔               |               ✔               |
| Data actions (inference, agents, etc.) |      ✔       |            ✔            |               ✔               |               ✔               |
| Create/manage projects                 |              |            ✔            |               ✔               |               ✔               |
| Manage Foundry accounts                |              |                         |               ✔               |               ✔               |
| Assign roles (conditional)             |              |    Foundry User only    | Foundry User, ACR, monitoring | Foundry User, ACR, monitoring |
| Deploy models (control plane)          |              |                         |               ✔               |               ✔               |

## Important Notes from Official Documentation

> **Do NOT assign** built-in roles that start with `Cognitive Services` for Foundry scenarios. These roles are designed for accessing AI Services resources directly and don't apply to Foundry.
>
> **Do NOT use** the `Azure AI Developer` role for Foundry work. Despite the name, this role is scoped to Azure Machine Learning workspaces and Foundry hubs (classic), not to Foundry projects or hosted agents. For Foundry project access, use **Foundry User** or **Foundry Owner** instead.

## Recommended Enterprise RBAC Mappings

| Persona                    | Role                    | Scope                            |
| -------------------------- | ----------------------- | -------------------------------- |
| IT Admin                   | Owner                   | Subscription                     |
| Manager                    | Foundry Account Owner   | Foundry resource                 |
| Team Lead / Lead Developer | Foundry Project Manager | Foundry resource                 |
| Team Member / Developer    | Foundry User + Reader   | Project scope + Foundry resource |

### Access Isolation Patterns

- **No isolation**: Grant all users `Foundry Owner` on the resource scope.
- **Partial isolation**: Grant admins `Foundry Account Owner`, grant developers/PMs `Foundry Project Manager`.
- **Full isolation**: Grant admins `Foundry Account Owner` on resource scope, developers `Reader` on Foundry resource + `Foundry User` on project scope, PMs `Foundry Project Manager` on resource scope.

## Module Usage

### Inputs

| Variable                     | Description                                                                | Default |
| ---------------------------- | -------------------------------------------------------------------------- | ------- |
| `foundry_account_id`         | Resource ID of the Foundry Account (RBAC scope)                            | —       |
| `foundry_project_id`         | Resource ID of the Foundry Project (RBAC scope)                            | —       |
| `deployer_principal_id`      | Principal ID of the deployer (empty to skip)                               | `""`    |
| `deployer_use_foundry_owner` | If true, assign Foundry Owner instead of Foundry Account Owner to deployer | `false` |
| `foundry_developer_group_id` | Object ID of the Foundry Developer group (empty to skip)                   | `""`    |
| `foundry_user_group_id`      | Object ID of the Foundry User group (empty to skip)                        | `""`    |

### Role Assignments (Full Isolation Pattern)

This module follows the official "full access isolation" pattern recommended by Microsoft.

| Principal       | Target Scope    | Role                                             | GUID                            |
| --------------- | --------------- | ------------------------------------------------ | ------------------------------- |
| Deployer        | Foundry Account | Foundry Account Owner (default) or Foundry Owner | `e47c6f54-...` / `c883944f-...` |
| Developer Group | Foundry Account | Foundry Project Manager                          | `eadc314b-...`                  |
| Developer Group | Foundry Project | Foundry Project Manager                          | `eadc314b-...`                  |
| User Group      | Foundry Account | Reader                                           | `acdd72a7-...`                  |
| User Group      | Foundry Project | Foundry User                                     | `53ca6127-...`                  |

> **Note**: All role assignments use `role_definition_id` (GUID-based) for stability during the Foundry RBAC role rename rollout.

## References

- [Role-based access control for Microsoft Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) (Updated: 2026-05-16)
- [Azure built-in roles for AI + machine learning](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning) (Updated: 2026-04-09)
- [Role-based access control for Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/role-based-access-control)
- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
