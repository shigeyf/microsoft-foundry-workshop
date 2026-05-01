#!/usr/bin/env bash
# destroy.sh — Teardown script for Microsoft Foundry Workshop (Bicep/basic)
#
# Deletes the resource group and purges soft-deleted Cognitive Services accounts
# to allow clean re-deployment.
#
# Usage:
#   export AZURE_RESOURCE_GROUP="rg-foundry-poc-jpe"
#   bash destroy.sh
#
#   Or pass environment variables inline:
#   AZURE_RESOURCE_GROUP=rg-... bash destroy.sh
#
# Required environment variables:
#   AZURE_RESOURCE_GROUP  Resource group name to delete
#
# Optional environment variables:
#   PURGE_COGNITIVE   Set to "true" to purge soft-deleted Cognitive Services accounts (default: true)
#   NO_WAIT           Set to "true" to return immediately without waiting (default: false)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:?Error: AZURE_RESOURCE_GROUP environment variable is required}"
PURGE_COGNITIVE="${PURGE_COGNITIVE:-true}"
NO_WAIT="${NO_WAIT:-false}"

# ---------------------------------------------------------------------------
# Step 1: Discover Cognitive Services accounts before deletion
# ---------------------------------------------------------------------------

echo ""
echo "=== Step 1: Discovering Cognitive Services accounts ==="

CS_ACCOUNTS=()
if [[ "${PURGE_COGNITIVE}" == "true" ]]; then
  while IFS= read -r line; do
    [[ -n "${line}" ]] && CS_ACCOUNTS+=("${line}")
  done < <(az cognitiveservices account list \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --query "[].{name:name, location:location}" \
    --output tsv 2>/dev/null || true)

  if [[ ${#CS_ACCOUNTS[@]} -gt 0 ]]; then
    echo "    Found ${#CS_ACCOUNTS[@]} Cognitive Services account(s) to purge after deletion:"
    for acct in "${CS_ACCOUNTS[@]}"; do
      echo "      - ${acct}"
    done
  else
    echo "    No Cognitive Services accounts found in '${AZURE_RESOURCE_GROUP}'."
  fi
else
  echo "    [SKIP] PURGE_COGNITIVE is not 'true'. Soft-deleted accounts will NOT be purged."
fi

# ---------------------------------------------------------------------------
# Step 2: Confirm
# ---------------------------------------------------------------------------

echo ""
echo "=== WARNING ==="
echo "    This will DELETE the resource group '${AZURE_RESOURCE_GROUP}' and ALL resources within it."
if [[ "${PURGE_COGNITIVE}" == "true" && ${#CS_ACCOUNTS[@]} -gt 0 ]]; then
  echo "    Cognitive Services accounts will be PURGED (permanent, unrecoverable)."
fi
echo ""
read -r -p "    Type the resource group name to confirm: " CONFIRM

if [[ "${CONFIRM}" != "${AZURE_RESOURCE_GROUP}" ]]; then
  echo "    Confirmation did not match. Aborting."
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 3: Delete resource group
# ---------------------------------------------------------------------------

echo ""
echo "=== Step 3: Deleting resource group '${AZURE_RESOURCE_GROUP}' ==="

DELETE_ARGS=(--name "${AZURE_RESOURCE_GROUP}" --yes)
if [[ "${NO_WAIT}" == "true" ]]; then
  DELETE_ARGS+=(--no-wait)
  echo "    (--no-wait: returning immediately without waiting for completion)"
fi

az group delete "${DELETE_ARGS[@]}"

echo "    Resource group deletion initiated."

# ---------------------------------------------------------------------------
# Step 4: Purge soft-deleted Cognitive Services accounts
# ---------------------------------------------------------------------------

if [[ "${PURGE_COGNITIVE}" == "true" && ${#CS_ACCOUNTS[@]} -gt 0 ]]; then
  echo ""
  echo "=== Step 4: Purging soft-deleted Cognitive Services accounts ==="

  # Wait for resource group deletion to propagate if --no-wait was used
  if [[ "${NO_WAIT}" == "true" ]]; then
    echo "    Waiting 60s for resource group deletion to propagate..."
    sleep 60
  fi

  for acct in "${CS_ACCOUNTS[@]}"; do
    # Each line is "name\tlocation"
    acct_name=$(echo "${acct}" | cut -f1)
    acct_location=$(echo "${acct}" | cut -f2)
    echo "    Purging '${acct_name}' in '${acct_location}'..."
    az cognitiveservices account purge \
      --name "${acct_name}" \
      --resource-group "${AZURE_RESOURCE_GROUP}" \
      --location "${acct_location}" 2>/dev/null || echo "    [WARN] Purge failed for '${acct_name}' (may not be soft-deleted yet)."
  done

  echo "    Purge complete."
else
  echo ""
  echo "=== Step 4: Skipped (no accounts to purge) ==="
fi

echo ""
echo "=== Teardown complete ==="
