#!/usr/bin/env bash
# deploy.sh — Deployment wrapper for Microsoft Foundry Workshop (Bicep/basic)
#
# This script automatically detects soft-deleted Azure resources that would
# conflict with a new deployment and sets restore parameters accordingly.
# Resource names are resolved by running 'az deployment group what-if' first,
# which evaluates the Bicep template (including uniqueString()) in ARM before
# the actual deployment.
#
# Usage:
#   export RG="rg-foundry-aipoc-dev-use2-xxxx"
#   export deployerObjectId="<your-entra-object-id>"
#   export aiDeveloperGroupId="<group-object-id>"   # optional, pass "" to skip
#   export aiUserGroupId="<group-object-id>"        # optional, pass "" to skip
#   bash deploy.sh
#
#   Or pass environment variables inline:
#   RG=rg-... deployerObjectId=... bash deploy.sh
#
# Required environment variables:
#   RG                  Resource group name
#   deployerObjectId    Entra ID Object ID of the deployer (for RBAC assignments)
#
# Optional environment variables:
#   aiDeveloperGroupId  Entra ID Object ID of AI Developer group (default: "")
#   aiUserGroupId       Entra ID Object ID of AI User group     (default: "")
#   LOCATION            Azure region for soft-delete lookup      (default: eastus2)
#   DEPLOYMENT_NAME     Deployment name prefix                   (default: auto-generated)
#   SCRIPT_DIR          Directory of this script                 (default: auto-detected)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/main.bicep"
PARAMS_FILE="${SCRIPT_DIR}/main.bicepparam"

RG="${RG:?Error: RG environment variable is required}"
deployerObjectId="${deployerObjectId:?Error: deployerObjectId environment variable is required}"
aiDeveloperGroupId="${aiDeveloperGroupId:-}"
aiUserGroupId="${aiUserGroupId:-}"
LOCATION="${LOCATION:?Error: LOCATION environment variable is required}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-deployment-foundry-basic-$(date +%Y%m%d-%H%M%S)}"

# ---------------------------------------------------------------------------
# Step 1: Resolve resource names via what-if
# ---------------------------------------------------------------------------

echo ""
echo "=== Step 1: Resolving resource names via what-if ==="
echo "    Resource group : ${RG}"
echo "    Template       : ${TEMPLATE_FILE}"
echo ""

WHAT_IF_JSON=$(az deployment group what-if \
  --resource-group "${RG}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAMS_FILE}" \
  --parameters deployerObjectId="${deployerObjectId}" \
  --parameters aiDeveloperGroupId="${aiDeveloperGroupId}" \
  --parameters aiUserGroupId="${aiUserGroupId}" \
  --no-pretty-print \
  --output json 2>/dev/null)

# Extract Key Vault name (Microsoft.KeyVault/vaults)
KV_NAME=$(echo "${WHAT_IF_JSON}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
changes = data.get('changes', [])
for c in changes:
    rid = c.get('resourceId', '')
    if '/Microsoft.KeyVault/vaults/' in rid and rid.count('/') == 8:
        print(rid.split('/')[-1])
        break
")

# Extract Foundry Account name (Microsoft.CognitiveServices/accounts, top-level only)
CS_NAME=$(echo "${WHAT_IF_JSON}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
changes = data.get('changes', [])
for c in changes:
    rid = c.get('resourceId', '')
    if '/Microsoft.CognitiveServices/accounts/' in rid \
       and '/projects/' not in rid \
       and '/deployments/' not in rid \
       and '/connections/' not in rid:
        print(rid.split('/')[-1])
        break
")

echo "    Key Vault name     : ${KV_NAME:-(not found)}"
echo "    Foundry Account name: ${CS_NAME:-(not found)}"

# ---------------------------------------------------------------------------
# Step 2: Check for soft-deleted resources
# ---------------------------------------------------------------------------

echo ""
echo "=== Step 2: Checking for soft-deleted resources ==="

EXTRA_PARAMS=""

# Key Vault soft-delete check
if [[ -n "${KV_NAME}" ]]; then
  if az keyvault show-deleted \
       --name "${KV_NAME}" \
       --location "${LOCATION}" \
       --output none 2>/dev/null; then
    echo "    [FOUND] Soft-deleted Key Vault '${KV_NAME}' detected."
    echo "            Adding --parameters keyvaultRestore=true"
    EXTRA_PARAMS="${EXTRA_PARAMS} --parameters keyvaultRestore=true"
  else
    echo "    [OK]    No soft-deleted Key Vault found for '${KV_NAME}'."
  fi
else
  echo "    [SKIP]  Could not resolve Key Vault name from what-if output."
fi

# Cognitive Services / Foundry Account soft-delete check
if [[ -n "${CS_NAME}" ]]; then
  CS_DELETED_COUNT=$(az cognitiveservices account list-deleted \
    --query "[?name=='${CS_NAME}'] | length(@)" \
    --output tsv 2>/dev/null || echo "0")
  if [[ "${CS_DELETED_COUNT}" =~ ^[1-9] ]]; then
    echo "    [FOUND] Soft-deleted Foundry Account '${CS_NAME}' detected."
    echo "            Adding --parameters foundryRestore=true"
    EXTRA_PARAMS="${EXTRA_PARAMS} --parameters foundryRestore=true"
  else
    echo "    [OK]    No soft-deleted Foundry Account found for '${CS_NAME}'."
  fi
else
  echo "    [SKIP]  Could not resolve Foundry Account name from what-if output."
fi

# ---------------------------------------------------------------------------
# Step 3: Deploy
# ---------------------------------------------------------------------------

echo ""
echo "=== Step 3: Deploying ==="
echo "    Deployment name : ${DEPLOYMENT_NAME}"
if [[ -n "${EXTRA_PARAMS}" ]]; then
  echo "    Extra params    :${EXTRA_PARAMS}"
fi
echo ""

# shellcheck disable=SC2086
az deployment group create \
  --name "${DEPLOYMENT_NAME}" \
  --resource-group "${RG}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAMS_FILE}" \
  --parameters deployerObjectId="${deployerObjectId}" \
  --parameters aiDeveloperGroupId="${aiDeveloperGroupId}" \
  --parameters aiUserGroupId="${aiUserGroupId}" \
  ${EXTRA_PARAMS}

echo ""
echo "=== Deployment complete ==="
