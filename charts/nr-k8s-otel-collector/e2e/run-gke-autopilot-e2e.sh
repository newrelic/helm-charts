#!/usr/bin/env bash
#
# Manual GKE Autopilot variant confirmation for nr-k8s-otel-collector.
#
# Runs test-specs-gke-autopilot.yml against an EXISTING GKE Autopilot cluster (never minikube). Three
# scenarios show what each knob buys: baseline (config fix, no allowlist) -> filesystem
# (gkeAutopilotAllowlist + CR) -> atp (+ process metrics). Each deploys the chart, applies its
# WorkloadAllowlist where needed, asserts the expected metrics, and tears down.
#
# Images: the published newrelic/nrdot-collector is used by default (the collector is not built from
# this repo). To test a dev collector you built and pushed yourself, set COLLECTOR_REGISTRY (and
# optionally COLLECTOR_TAG) and the runner will --set images.collector.* accordingly.
#
# REGION selects the New Relic backend (US | EU | Staging | Local). GKE Autopilot testing uses a
# production account, so this is normally US. When Staging, the agent gets global.nrStaging=true.
#
# Self-guiding: config is resolved from environment -> .env -> interactive prompt. It NEVER switches
# kube-context, gcloud account, or docker identity (hard rule).
#
# Usage:  bash e2e/run-gke-autopilot-e2e.sh   (from the chart dir: charts/nr-k8s-otel-collector)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../e2e
CHART_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"                    # .../nr-k8s-otel-collector
ENV_FILE="$SCRIPT_DIR/gke-autopilot-allowlists/.env"

# Tee all output (terminal + a timestamped log) so the latest run can be read from disk. results/ is
# gitignored. results/latest.log always points at the most recent run.
RESULTS_DIR="$SCRIPT_DIR/gke-autopilot-allowlists/results"
mkdir -p "$RESULTS_DIR"
RUN_LOG="$RESULTS_DIR/run-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$RUN_LOG") 2>&1
ln -sf "$(basename "$RUN_LOG")" "$RESULTS_DIR/latest.log"
echo "Logging this run to: $RUN_LOG"
echo "Latest run always at: $RESULTS_DIR/latest.log"
echo

DEFAULT_KUBE_CONTEXT="gke_k8s-o11y-team_us-west2_gke-autopilot-truong"
DEFAULT_REGION="US"   # US | EU | Staging | Local

PROMPTED=()

if [[ -f "$ENV_FILE" ]]; then
  echo "Loading saved config from $ENV_FILE"
  set -a; # shellcheck disable=SC1090
  source "$ENV_FILE"; set +a
fi

prompt_var() { # name prompt secret default
  local name="$1" prompt="$2" secret="$3" default="$4"
  if [[ -n "${!name:-}" ]]; then return; fi
  local input=""
  if [[ "$secret" == "secret" ]]; then
    read -rsp "  $prompt: " input; echo
  elif [[ -n "$default" ]]; then
    read -rp "  $prompt [$default]: " input; input="${input:-$default}"
  else
    read -rp "  $prompt: " input
  fi
  printf -v "$name" '%s' "$input"
  PROMPTED+=("$name")
}

echo "Enter any missing config (press enter to accept a [default]):"
prompt_var KUBE_CONTEXT  "Kube context"                              "" "$DEFAULT_KUBE_CONTEXT"
prompt_var REGION        "New Relic region (US|EU|Staging|Local)"    "" "$DEFAULT_REGION"
prompt_var ACCOUNT_ID    "New Relic account ID (must match REGION + keys)" ""     ""
prompt_var API_KEY       "New Relic USER API key"                          secret ""
prompt_var LICENSE_KEY   "New Relic INGEST license key"                     secret ""

if [[ ${#PROMPTED[@]} -gt 0 ]]; then
  read -rp "Save these to $ENV_FILE for next time? [y/N]: " save || true
  if [[ "${save:-}" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$ENV_FILE")"
    {
      echo "# gke-autopilot otel e2e config — gitignored, DO NOT commit."
      echo "KUBE_CONTEXT=$KUBE_CONTEXT"
      echo "REGION=$REGION"
      echo "ACCOUNT_ID=$ACCOUNT_ID"
      echo "API_KEY=$API_KEY"
      echo "LICENSE_KEY=$LICENSE_KEY"
      echo "# optional dev collector image (leave unset to use the published newrelic/nrdot-collector):"
      echo "COLLECTOR_REGISTRY=${COLLECTOR_REGISTRY:-}"
      echo "COLLECTOR_TAG=${COLLECTOR_TAG:-}"
    } > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "Saved to $ENV_FILE (chmod 600)."
  fi
fi

echo
echo "──────── config ────────"
echo "  KUBE_CONTEXT : $KUBE_CONTEXT"
echo "  REGION       : $REGION"
echo "  ACCOUNT_ID   : $ACCOUNT_ID"
echo "  API_KEY      : ${API_KEY:0:4}… (${#API_KEY} chars)"
echo "  LICENSE_KEY  : ${LICENSE_KEY:0:4}… (${#LICENSE_KEY} chars)"
echo "  COLLECTOR    : ${COLLECTOR_REGISTRY:-<published newrelic/nrdot-collector>}${COLLECTOR_TAG:+ :$COLLECTOR_TAG}"
echo "────────────────────────"
echo

# Extra helm --set flags consumed by the spec's before-block.
EXTRA_HELM_ARGS=""
if [[ "$REGION" == "Staging" ]]; then
  EXTRA_HELM_ARGS="$EXTRA_HELM_ARGS --set global.nrStaging=true"
fi
if [[ -n "${COLLECTOR_REGISTRY:-}" ]]; then
  EXTRA_HELM_ARGS="$EXTRA_HELM_ARGS --set images.collector.registry=$COLLECTOR_REGISTRY"
  [[ -n "${COLLECTOR_TAG:-}" ]] && EXTRA_HELM_ARGS="$EXTRA_HELM_ARGS --set images.collector.tag=$COLLECTOR_TAG"
fi

# --- preflight: kube-context (NEVER switch it) ---
CURRENT_CTX="$(kubectl config current-context 2>/dev/null || true)"
if [[ "$CURRENT_CTX" != "$KUBE_CONTEXT" ]]; then
  cat <<EOF
Active kube-context is '$CURRENT_CTX', expected '$KUBE_CONTEXT'.
This script does NOT switch contexts. Switch it yourself, then re-run:
    kubectl config use-context $KUBE_CONTEXT
EOF
  exit 1
fi
echo "kube-context OK: $KUBE_CONTEXT"

# --- helm repos for subchart deps (common-library, kube-state-metrics) ---
helm repo add newrelic https://helm-charts.newrelic.com >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update newrelic prometheus-community >/dev/null 2>&1 || true

# --- run the e2e action (before-blocks run from the spec dir e2e/ and consume these env vars) ---
echo "Running GKE Autopilot OTel e2e (spec: test-specs-gke-autopilot.yml, 3 variants, region=$REGION)…"
export EXTRA_HELM_ARGS LICENSE_KEY ACCOUNT_ID API_KEY
cd "$CHART_DIR"
go run github.com/newrelic/newrelic-integration-e2e-action@latest \
  --commit_sha=gke-autopilot-manual --retry_attempts=8 --retry_seconds=60 --region="$REGION" \
  --account_id="$ACCOUNT_ID" --api_key="$API_KEY" --license_key="$LICENSE_KEY" \
  --spec_path=./e2e/test-specs-gke-autopilot.yml --verbose_mode=true --agent_enabled=false

echo "Done. Review the pass/fail summary above."
