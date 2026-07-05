#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/terraform"
TFVARS_FILE="${TFVARS_FILE:-envs/dev.tfvars}"

LOCATION="${LOCATION:-West Europe}"
DEMO_RG="${DEMO_RG:-rg-aks-gitops-demo-dev}"
AKS_NAME="${AKS_NAME:-aks-gitops-demo-dev}"
VNET_NAME="${VNET_NAME:-vnet-aks-gitops-demo-dev}"

TF_STATE_RG="${TF_STATE_RG:-}"
TF_STATE_STORAGE_ACCOUNT="${TF_STATE_STORAGE_ACCOUNT:-}"
TF_STATE_CONTAINER="${TF_STATE_CONTAINER:-}"
TF_STATE_KEY="${TF_STATE_KEY:-aks-flux-dev.tfstate}"

usage() {
  cat <<'EOF'
Usage:
  ./deploy.sh plan
  ./deploy.sh apply
  ./deploy.sh verify

Required for plan/apply:
  ARM_CLIENT_ID             Azure service principal app/client ID
  ARM_CLIENT_SECRET         Azure service principal secret
  ARM_TENANT_ID             Azure tenant ID. Optional only if an existing az login can provide it.
  ARM_SUBSCRIPTION_ID       Azure subscription ID. Optional only if an existing/default az account can provide it.
  ADMIN_GROUP_OBJECT_ID     Entra ID group object ID for AKS admin access
                            OR ADMIN_GROUP_OBJECT_IDS as a comma-separated list
  TF_STATE_RG               Azure resource group containing the Terraform state storage account
  TF_STATE_STORAGE_ACCOUNT  Azure Storage account for Terraform state
  TF_STATE_CONTAINER        Azure Blob container for Terraform state

Optional:
  LOCATION                  Default: West Europe
  DEMO_RG                   Default: rg-aks-gitops-demo-dev
  AKS_NAME                  Default: aks-gitops-demo-dev
  VNET_NAME                 Default: vnet-aks-gitops-demo-dev
  TF_STATE_KEY              Default: aks-flux-dev.tfstate
  TFVARS_FILE               Default: envs/dev.tfvars

Notes:
  - This script never prints ARM_CLIENT_SECRET.
  - Terraform generates Flux SSH deploy keys and stores private keys in Terraform state.
  - Protect the AzureRM Terraform state backend as sensitive secret storage.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "Missing required environment variable: ${name}"
}

az_account_value() {
  local query="$1"
  az account show --query "${query}" --output tsv 2>/dev/null || true
}

resolve_azure_context_from_current_login() {
  if [[ -z "${ARM_TENANT_ID:-}" ]]; then
    ARM_TENANT_ID="$(az_account_value tenantId)"
    export ARM_TENANT_ID
    [[ -n "${ARM_TENANT_ID}" ]] && echo "Using tenant ID from current Azure CLI account."
  fi

  if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    ARM_SUBSCRIPTION_ID="$(az_account_value id)"
    export ARM_SUBSCRIPTION_ID
    [[ -n "${ARM_SUBSCRIPTION_ID}" ]] && echo "Using subscription ID from current Azure CLI account."
  fi
}

admin_group_ids_json() {
  local ids="${ADMIN_GROUP_OBJECT_IDS:-${ADMIN_GROUP_OBJECT_ID:-}}"
  [[ -n "${ids}" ]] || fail "Set ADMIN_GROUP_OBJECT_ID or ADMIN_GROUP_OBJECT_IDS. AKS local accounts are disabled, so empty admin_group_object_ids can lock you out."

  IDS="${ids}" python3 - <<'PY'
import json, os
ids = [item.strip() for item in os.environ["IDS"].split(",") if item.strip()]
if not ids:
    raise SystemExit("[]")
print(json.dumps(ids))
PY
}

login_azure() {
  require_cmd az
  require_env ARM_CLIENT_ID
  require_env ARM_CLIENT_SECRET

  resolve_azure_context_from_current_login

  require_env ARM_TENANT_ID

  echo "Logging in to Azure as service principal ${ARM_CLIENT_ID} ..."
  az login \
    --service-principal \
    --username "${ARM_CLIENT_ID}" \
    --password "${ARM_CLIENT_SECRET}" \
    --tenant "${ARM_TENANT_ID}" \
    --output none

  if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    ARM_SUBSCRIPTION_ID="$(az_account_value id)"
    export ARM_SUBSCRIPTION_ID
    [[ -n "${ARM_SUBSCRIPTION_ID}" ]] && echo "Using subscription ID from service principal login."
  fi

  require_env ARM_SUBSCRIPTION_ID
  az account set --subscription "${ARM_SUBSCRIPTION_ID}"
}

terraform_init() {
  require_env TF_STATE_RG
  require_env TF_STATE_STORAGE_ACCOUNT
  require_env TF_STATE_CONTAINER

  terraform -chdir="${TF_DIR}" init \
    -input=false \
    -reconfigure \
    -backend-config="resource_group_name=${TF_STATE_RG}" \
    -backend-config="storage_account_name=${TF_STATE_STORAGE_ACCOUNT}" \
    -backend-config="container_name=${TF_STATE_CONTAINER}" \
    -backend-config="key=${TF_STATE_KEY}"
}

terraform_common_args() {
  local admin_ids
  admin_ids="$(admin_group_ids_json)"

  printf '%s\0' \
    "-var-file=${TFVARS_FILE}" \
    "-var=resource_group_name=${DEMO_RG}" \
    "-var=location=${LOCATION}" \
    "-var=aks_name=${AKS_NAME}" \
    "-var=vnet_name=${VNET_NAME}" \
    "-var=admin_group_object_ids=${admin_ids}"
}

run_plan() {
  require_cmd terraform
  require_cmd python3

  login_azure

  echo "Ensuring demo resource group exists: ${DEMO_RG} (${LOCATION})"
  az group create --name "${DEMO_RG}" --location "${LOCATION}" --output none

  terraform_init
  terraform -chdir="${TF_DIR}" fmt -check -recursive
  terraform -chdir="${TF_DIR}" validate -no-color

  local args=()
  while IFS= read -r -d '' arg; do args+=("$arg"); done < <(terraform_common_args)

  terraform -chdir="${TF_DIR}" plan -input=false -no-color "${args[@]}"
}

run_apply() {
  require_cmd terraform
  require_cmd python3

  login_azure

  echo "Ensuring demo resource group exists: ${DEMO_RG} (${LOCATION})"
  az group create --name "${DEMO_RG}" --location "${LOCATION}" --output none

  terraform_init
  terraform -chdir="${TF_DIR}" fmt -check -recursive
  terraform -chdir="${TF_DIR}" validate -no-color

  local args=()
  while IFS= read -r -d '' arg; do args+=("$arg"); done < <(terraform_common_args)

  terraform -chdir="${TF_DIR}" apply -input=false -no-color "${args[@]}"

  echo
  echo "Flux deploy public keys. Add each key to the matching private GitHub app repo as a read-only deploy key:"
  terraform -chdir="${TF_DIR}" output -no-color flux_repository_deploy_public_keys || true
}

run_verify() {
  require_cmd az
  require_cmd kubectl

  if [[ -n "${ARM_CLIENT_ID:-}" || -n "${ARM_CLIENT_SECRET:-}" || -n "${ARM_TENANT_ID:-}" || -n "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    login_azure
  fi

  echo "Fetching AKS credentials for ${AKS_NAME} in ${DEMO_RG} ..."
  az aks get-credentials \
    --resource-group "${DEMO_RG}" \
    --name "${AKS_NAME}" \
    --overwrite-existing

  echo
  echo "Flux pods:"
  kubectl get pods -n flux-system

  echo
  echo "Flux GitRepository/Kustomization resources, if CRDs are available:"
  kubectl get gitrepositories,kustomizations -A || true

  echo
  echo "Storefront resources:"
  kubectl get pods,svc -n storefront

  echo
  echo "Admin resources:"
  kubectl get pods,svc -n admin

  cat <<'EOF'

Port-forward smoke tests:
  kubectl -n storefront port-forward svc/storefront 8080:80
  curl http://127.0.0.1:8080/

  kubectl -n admin port-forward svc/admin 8081:80
  curl http://127.0.0.1:8081/
EOF
}

case "${ACTION}" in
  plan)
    run_plan
    ;;
  apply)
    run_apply
    ;;
  verify)
    run_verify
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    usage >&2
    fail "Unknown action: ${ACTION}"
    ;;
esac
