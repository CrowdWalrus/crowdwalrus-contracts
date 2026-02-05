#!/usr/bin/env bash

# Phase 2 post-deployment automation for Crowd Walrus on Sui.
# - Verifies all recorded IDs from a deployment JSON against chain state.
# - Applies post-deployment configuration (policies, tokens, badges, SuiNS) using Sui CLI.
# - Designed to be config-driven and idempotent for fresh publishes and subsequent re-runs.
#
# Usage:
#   ./scripts/post_deploy_phase2.sh [deployment_json] [mode]
#     deployment_json: path to deployment JSON (default: deployment.addresses.testnet.2025-11-11.json)
#     mode:            "dry-run" (default) or "apply"
#
# In dry-run mode the script only prints the Sui CLI commands it would run.
# In apply mode it executes those commands against the active Sui environment.

set -euo pipefail

default_config_file() {
  local latest
  latest=$(ls -1 deployment.addresses.testnet.*.json 2>/dev/null | sort | tail -n 1 || true)
  if [[ -n "${latest}" ]]; then
    echo "${latest}"
    return 0
  fi

  if [[ -f "deployment.addresses.testnet.json" ]]; then
    echo "deployment.addresses.testnet.json"
    return 0
  fi

  echo "deployment.addresses.testnet.2025-11-11.json"
}

CONFIG_FILE="${1:-$(default_config_file)}"
MODE="${2:-dry-run}" # "dry-run" or "apply"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found on PATH." >&2
  exit 1
fi

if ! command -v sui >/dev/null 2>&1; then
  echo "ERROR: sui CLI is required but not found on PATH." >&2
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "ERROR: Config file not found: ${CONFIG_FILE}" >&2
  exit 1
fi

if [[ "${MODE}" != "dry-run" && "${MODE}" != "apply" ]]; then
  echo "ERROR: Mode must be 'dry-run' or 'apply', got: ${MODE}" >&2
  exit 1
fi

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

run_or_print() {
  # Print the command first for auditability.
  echo "+ $*"
  if [[ "${MODE}" == "apply" ]]; then
    "$@"
  fi
}

CONFIG_NETWORK=$(jq -r '.network' "${CONFIG_FILE}")
PACKAGE_ID=$(jq -r '.packageId' "${CONFIG_FILE}")
DEPLOYER_ADDR=$(jq -r '.accounts.deployer' "${CONFIG_FILE}")

CROWD_WALRUS_ID=$(jq -r '.sharedObjects.crowdWalrus' "${CONFIG_FILE}")
SUINS_MANAGER_ID=$(jq -r '.sharedObjects.suinsManager' "${CONFIG_FILE}")
POLICY_REGISTRY_ID=$(jq -r '.sharedObjects.policyRegistry' "${CONFIG_FILE}")
PROFILES_REGISTRY_ID=$(jq -r '.sharedObjects.profilesRegistry' "${CONFIG_FILE}")
BADGE_CONFIG_ID=$(jq -r '.sharedObjects.badgeConfig' "${CONFIG_FILE}")
TOKEN_REGISTRY_ID=$(jq -r '.sharedObjects.tokenRegistry' "${CONFIG_FILE}")

ADMIN_CAP_ID=$(jq -r '.ownedCaps.adminCap' "${CONFIG_FILE}")
SUINS_ADMIN_CAP_ID=$(jq -r '.ownedCaps.suinsAdminCap' "${CONFIG_FILE}")
PUBLISHER_ID=$(jq -r '.ownedCaps.publisher' "${CONFIG_FILE}")
UPGRADE_CAP_ID=$(jq -r '.ownedCaps.upgradeCap' "${CONFIG_FILE}")

CLOCK_ID=$(jq -r '.globals.clock' "${CONFIG_FILE}")
PYTH_STATE_ID=$(jq -r '.globals.pythState' "${CONFIG_FILE}")
WORMHOLE_STATE_ID=$(jq -r '.globals.wormholeState' "${CONFIG_FILE}")
SUINS_PACKAGE_ID=$(jq -r '.globals.suinsPackage // empty' "${CONFIG_FILE}")

SUINS_NFT_ID=$(jq -r '.migration.suinsRegistration.nftId' "${CONFIG_FILE}")

BADGE_DISPLAY_ID=$(jq -r '.postConfig.display.donorBadgeDisplay' "${CONFIG_FILE}")

log "Using config file: ${CONFIG_FILE}"
log "Mode: ${MODE}"
log "Network (config): ${CONFIG_NETWORK}"
log "Package ID: ${PACKAGE_ID}"
log "Deployer address: ${DEPLOYER_ADDR}"

ACTIVE_ENV=$(sui client active-env | tail -n 1 || true)
if [[ -n "${ACTIVE_ENV}" && "${ACTIVE_ENV}" != "${CONFIG_NETWORK}" ]]; then
  echo "ERROR: Active Sui env '${ACTIVE_ENV}' does not match config network '${CONFIG_NETWORK}'." >&2
  echo "       Run: sui client switch --env ${CONFIG_NETWORK}" >&2
  exit 1
fi

log "Verified active Sui env: ${ACTIVE_ENV}"

check_object_type() {
  local object_id="$1"
  local expected_type="$2"
  local label="$3"

  local actual_type
  actual_type=$(sui client object "${object_id}" --json | jq -r '.type')
  if [[ "${actual_type}" != "${expected_type}" ]]; then
    echo "ERROR: ${label} type mismatch for object ${object_id}" >&2
    echo "       Expected: ${expected_type}" >&2
    echo "       Actual:   ${actual_type}" >&2
    exit 1
  fi
  log "Verified ${label} type: ${actual_type}"
}

log "Verifying core objects against package types..."
check_object_type "${CROWD_WALRUS_ID}"    "${PACKAGE_ID}::crowd_walrus::CrowdWalrus"          "CrowdWalrus"
check_object_type "${SUINS_MANAGER_ID}"   "${PACKAGE_ID}::suins_manager::SuiNSManager"        "SuiNSManager"
check_object_type "${POLICY_REGISTRY_ID}" "${PACKAGE_ID}::platform_policy::PolicyRegistry"    "PolicyRegistry"
check_object_type "${PROFILES_REGISTRY_ID}" "${PACKAGE_ID}::profiles::ProfilesRegistry"       "ProfilesRegistry"
check_object_type "${BADGE_CONFIG_ID}"    "${PACKAGE_ID}::badge_rewards::BadgeConfig"         "BadgeConfig"
check_object_type "${TOKEN_REGISTRY_ID}"  "${PACKAGE_ID}::token_registry::TokenRegistry"      "TokenRegistry"

check_object_type "${ADMIN_CAP_ID}"       "${PACKAGE_ID}::crowd_walrus::AdminCap"             "AdminCap"
check_object_type "${SUINS_ADMIN_CAP_ID}" "${PACKAGE_ID}::suins_manager::AdminCap"            "SuiNS AdminCap"
check_object_type "${PUBLISHER_ID}"       "0x2::package::Publisher"                           "Publisher"
check_object_type "${UPGRADE_CAP_ID}"     "0x2::package::UpgradeCap"                          "UpgradeCap"

if [[ -n "${BADGE_DISPLAY_ID}" && "${BADGE_DISPLAY_ID}" != "null" ]]; then
  check_object_type "${BADGE_DISPLAY_ID}"   "0x2::display::Display<${PACKAGE_ID}::badge_rewards::DonorBadge>" "DonorBadge Display"
fi

if [[ -n "${SUINS_PACKAGE_ID}" && "${SUINS_PACKAGE_ID}" != "null" ]]; then
  check_object_type "${SUINS_NFT_ID}"       "${SUINS_PACKAGE_ID}::suins_registration::SuinsRegistration" "SuinsRegistration NFT"
fi

log "Core object verification complete."

ensure_suins_registration() {
  log "Checking SuiNS registration under SuiNSManager..."

  # Look for the RegKey dynamic field, which holds the SuinsRegistration NFT.
  local reg_object_id
  reg_object_id=$(sui client dynamic-field "${SUINS_MANAGER_ID}" --json \
    | jq -r '.data[]? | select(.name.type | endswith("::suins_manager::RegKey")) | .objectId' || true)

  if [[ -n "${reg_object_id}" ]]; then
    if [[ "${reg_object_id}" != "${SUINS_NFT_ID}" ]]; then
      echo "ERROR: SuiNSManager already has a SuinsRegistration (${reg_object_id})" >&2
      echo "       which does not match config.nftId (${SUINS_NFT_ID})." >&2
      exit 1
    fi
    log "SuiNS registration is already configured (NFT: ${reg_object_id})."
    return 0
  fi

  log "SuiNS registration not found on-chain. Will call suins_manager::set_suins_nft..."
  run_or_print sui client call \
    --package "${PACKAGE_ID}" \
    --module suins_manager \
    --function set_suins_nft \
    --args "${SUINS_MANAGER_ID}" "${SUINS_ADMIN_CAP_ID}" "${SUINS_NFT_ID}" \
    --gas-budget 15000000
}

ensure_token_config() {
  local coin_type="$1"

  local symbol_json name_json decimals feed_id max_age_ms enabled
  symbol_json=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].symbol | @json' "${CONFIG_FILE}")
  name_json=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].name | @json' "${CONFIG_FILE}")
  decimals=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].decimals' "${CONFIG_FILE}")
  feed_id=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].feedId' "${CONFIG_FILE}")
  max_age_ms=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].maxAgeMs' "${CONFIG_FILE}")
  enabled=$(jq -r --arg t "${coin_type}" '.postConfig.tokens[$t].enabled' "${CONFIG_FILE}")

  if [[ "${symbol_json}" == "null" || "${name_json}" == "null" ]]; then
    echo "ERROR: Missing symbol/name for token '${coin_type}' in ${CONFIG_FILE}" >&2
    exit 1
  fi

  log "Ensuring token metadata for ${coin_type}..."

  # Look for existing TokenMetadata dynamic field for this coin type.
  local meta_object_id
  meta_object_id=$(sui client dynamic-field "${TOKEN_REGISTRY_ID}" --json \
    | jq -r --arg t "${coin_type}" '.data[]? | select(.name.type | contains($t)) | .objectId' || true)

  if [[ -z "${meta_object_id}" ]]; then
    log "Token ${coin_type} not found in registry. Will call add_token + set_token_enabled..."
    run_or_print sui client call \
      --package "${PACKAGE_ID}" \
      --module crowd_walrus \
      --function add_token \
      --type-args "${coin_type}" \
      --args \
        "${TOKEN_REGISTRY_ID}" \
        "${ADMIN_CAP_ID}" \
        "${symbol_json}" \
        "${name_json}" \
        "${decimals}" \
        "${feed_id}" \
        "${max_age_ms}" \
        "${CLOCK_ID}" \
      --gas-budget 20000000

    if [[ "${enabled}" == "true" ]]; then
      run_or_print sui client call \
        --package "${PACKAGE_ID}" \
        --module crowd_walrus \
        --function set_token_enabled \
        --type-args "${coin_type}" \
        --args \
          "${TOKEN_REGISTRY_ID}" \
          "${ADMIN_CAP_ID}" \
          true \
          "${CLOCK_ID}" \
        --gas-budget 10000000
    fi
    return 0
  fi

  log "Token ${coin_type} already exists (metadata object: ${meta_object_id}). Updating metadata..."

  # Always update metadata to match config, then ensure enabled/max_age_ms.
  run_or_print sui client call \
    --package "${PACKAGE_ID}" \
    --module crowd_walrus \
    --function update_token_metadata \
    --type-args "${coin_type}" \
    --args \
      "${TOKEN_REGISTRY_ID}" \
      "${ADMIN_CAP_ID}" \
      "${symbol_json}" \
      "${name_json}" \
      "${decimals}" \
      "${feed_id}" \
      "${CLOCK_ID}" \
    --gas-budget 20000000

  run_or_print sui client call \
    --package "${PACKAGE_ID}" \
    --module crowd_walrus \
    --function set_token_max_age \
    --type-args "${coin_type}" \
    --args \
      "${TOKEN_REGISTRY_ID}" \
      "${ADMIN_CAP_ID}" \
      "${max_age_ms}" \
      "${CLOCK_ID}" \
    --gas-budget 10000000

  run_or_print sui client call \
    --package "${PACKAGE_ID}" \
    --module crowd_walrus \
    --function set_token_enabled \
    --type-args "${coin_type}" \
    --args \
      "${TOKEN_REGISTRY_ID}" \
      "${ADMIN_CAP_ID}" \
      "${enabled}" \
      "${CLOCK_ID}" \
    --gas-budget 10000000
}

ensure_badge_config() {
  log "Ensuring badge thresholds and image URIs..."

  local amounts_json payments_json images_json
  amounts_json=$(jq -c '.postConfig.badges.amountThresholdsMicro' "${CONFIG_FILE}")
  payments_json=$(jq -c '.postConfig.badges.paymentThresholds' "${CONFIG_FILE}")
  images_json=$(jq -c '.postConfig.badges.imageUris' "${CONFIG_FILE}")

  if [[ "${amounts_json}" == "null" || "${payments_json}" == "null" || "${images_json}" == "null" ]]; then
    echo "ERROR: Missing badge configuration vectors in ${CONFIG_FILE}" >&2
    exit 1
  fi

  run_or_print sui client call \
    --package "${PACKAGE_ID}" \
    --module crowd_walrus \
    --function update_badge_config \
    --args \
      "${BADGE_CONFIG_ID}" \
      "${ADMIN_CAP_ID}" \
      "${amounts_json}" \
      "${payments_json}" \
      "${images_json}" \
      "${CLOCK_ID}" \
    --gas-budget 25000000
}

ensure_policies() {
  log "Ensuring platform policies..."

  local policies_json
  policies_json=$(jq -c '.postConfig.policies' "${CONFIG_FILE}")
  if [[ "${policies_json}" == "null" || "${policies_json}" == "{}" ]]; then
    log "No custom policies defined in config; skipping policy updates."
    return 0
  fi

  # Policies are stored in a table; fetch its object ID once.
  local policy_table_id
  policy_table_id=$(sui client object "${POLICY_REGISTRY_ID}" --json | jq -r '.content.fields.policies.fields.id.id')

  if [[ -z "${policy_table_id}" || "${policy_table_id}" == "null" ]]; then
    echo "ERROR: Could not extract policy table ID from PolicyRegistry ${POLICY_REGISTRY_ID}" >&2
    exit 1
  fi

  # Iterate over configured policy presets (e.g. "standard", "commercial").
  local policy_names
  policy_names=$(jq -r '.postConfig.policies | keys[]' "${CONFIG_FILE}")

  local name
  for name in ${policy_names}; do
    local bps platform_addr enabled
    bps=$(jq -r --arg n "${name}" '.postConfig.policies[$n].bps' "${CONFIG_FILE}")
    platform_addr=$(jq -r --arg n "${name}" '.postConfig.policies[$n].platformAddress' "${CONFIG_FILE}")
    enabled=$(jq -r --arg n "${name}" '.postConfig.policies[$n].enabled' "${CONFIG_FILE}")

    local name_json policy_exists
    name_json=$(jq -rn --arg n "${name}" '$n | @json')

    # Does this policy already exist in the registry table?
    policy_exists=$(sui client dynamic-field "${policy_table_id}" --json \
      | jq -r --arg n "${name}" '.data[]? | select(.name.type == "0x1::string::String" and .name.value == $n) | .objectId' || true)

    if [[ -z "${policy_exists}" ]]; then
      log "Policy '${name}' not found. Will call add_platform_policy..."
      run_or_print sui client call \
        --package "${PACKAGE_ID}" \
        --module crowd_walrus \
        --function add_platform_policy \
        --args \
          "${POLICY_REGISTRY_ID}" \
          "${ADMIN_CAP_ID}" \
          "${name_json}" \
          "${bps}" \
          "${platform_addr}" \
          "${CLOCK_ID}" \
        --gas-budget 15000000
    else
      log "Updating existing policy '${name}' to ${bps} bps, platformAddress=${platform_addr}..."
      run_or_print sui client call \
        --package "${PACKAGE_ID}" \
        --module crowd_walrus \
        --function update_platform_policy \
        --args \
          "${POLICY_REGISTRY_ID}" \
          "${ADMIN_CAP_ID}" \
          "${name_json}" \
          "${bps}" \
          "${platform_addr}" \
          "${CLOCK_ID}" \
        --gas-budget 15000000
    fi

    local func="enable_platform_policy"
    if [[ "${enabled}" != "true" ]]; then
      func="disable_platform_policy"
    fi

    run_or_print sui client call \
      --package "${PACKAGE_ID}" \
      --module crowd_walrus \
      --function "${func}" \
      --args \
        "${POLICY_REGISTRY_ID}" \
        "${ADMIN_CAP_ID}" \
        "${name_json}" \
        "${CLOCK_ID}" \
      --gas-budget 10000000
  done
}

ensure_badge_display() {
  log "Ensuring donor badge Display object..."

  # If a Display ID is present in config, just verify it.
  if [[ -n "${BADGE_DISPLAY_ID}" && "${BADGE_DISPLAY_ID}" != "null" ]]; then
    check_object_type "${BADGE_DISPLAY_ID}" "0x2::display::Display<${PACKAGE_ID}::badge_rewards::DonorBadge>" "DonorBadge Display"
    return 0
  fi

  log "No Display ID in config; will create Display via badge_rewards::setup_badge_display (apply mode only)."

  local expected_type="0x2::display::Display<${PACKAGE_ID}::badge_rewards::DonorBadge>"

  if [[ "${MODE}" == "apply" ]]; then
    # Create the Display object and share it; capture its ID so the operator can update JSON.
    log "Calling badge_rewards::setup_badge_display..."
    local tx_json
    echo "+ sui client call --package ${PACKAGE_ID} --module badge_rewards --function setup_badge_display --args ${PUBLISHER_ID} --gas-budget 15000000"
    tx_json=$(sui client call \
      --package "${PACKAGE_ID}" \
      --module badge_rewards \
      --function setup_badge_display \
      --args "${PUBLISHER_ID}" \
      --gas-budget 15000000 \
      --json)

    local new_display_id
    new_display_id=$(echo "${tx_json}" | jq -r --arg et "${expected_type}" '.objectChanges[]? | select(.objectType == $et) | .objectId' || true)

    if [[ -z "${new_display_id}" || "${new_display_id}" == "null" ]]; then
      echo "WARNING: Could not automatically extract DonorBadge Display ID from transaction; check the tx output manually." >&2
    else
      log "Created DonorBadge Display with objectId=${new_display_id}."
      log "Update your deployment JSON under postConfig.display.donorBadgeDisplay with this ID."
    fi
  else
    echo "+ sui client call --package ${PACKAGE_ID} --module badge_rewards --function setup_badge_display --args ${PUBLISHER_ID} --gas-budget 15000000"
    log "Dry-run mode: Display will be created on apply; remember to capture its ID from the transaction."
  fi
}

main() {
  log "Starting post-deployment verification and configuration..."

  ensure_suins_registration

  # Tokens (SUI, USDC, etc.)
  local token_types
  token_types=$(jq -r '.postConfig.tokens | keys[]' "${CONFIG_FILE}")
  for t in ${token_types}; do
    ensure_token_config "${t}"
  done

  ensure_badge_config
  ensure_policies
  ensure_badge_display

  log "Post-deployment script completed (mode=${MODE})."
}

main "$@"
