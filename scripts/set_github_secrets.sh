#!/usr/bin/env bash
# Creates the GitHub Actions secrets/variables required by the pipeline.
#
# Reads WIF_PROVIDER and DEPLOYER_SA from the Terraform `bootstrap` outputs and
# sets the secrets on the GitHub repo via the `gh` CLI. Project ids and Astro
# values are passed as flags.
#
# Prereqs: `gh auth login`, and the bootstrap stack already applied.
#
# Usage:
#   scripts/set_github_secrets.sh \
#     --repo owner/music-stream-rawdp \
#     --project-dev music-stream-dev-123 \
#     --project-prd music-stream-prd-123 \
#     [--region europe-west1] \
#     [--astro-token <token>] \
#     [--astro-dev <deployment-id>] [--astro-prd <deployment-id>]
set -euo pipefail

REPO="" PROJECT_DEV="" PROJECT_PRD="" REGION="europe-west1"
WIF_PROVIDER="" DEPLOYER_SA="" ASTRO_TOKEN="" ASTRO_DEV="" ASTRO_PRD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --project-dev) PROJECT_DEV="$2"; shift 2;;
    --project-prd) PROJECT_PRD="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --wif-provider) WIF_PROVIDER="$2"; shift 2;;
    --deployer-sa) DEPLOYER_SA="$2"; shift 2;;
    --astro-token) ASTRO_TOKEN="$2"; shift 2;;
    --astro-dev) ASTRO_DEV="$2"; shift 2;;
    --astro-prd) ASTRO_PRD="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

[[ -z "$REPO" || -z "$PROJECT_DEV" || -z "$PROJECT_PRD" ]] && {
  echo "Missing required: --repo --project-dev --project-prd" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/../infrastructure/projects/bootstrap"

tf_out() { terraform -chdir="$BOOTSTRAP_DIR" output -raw "$1"; }

[[ -z "$WIF_PROVIDER" ]] && WIF_PROVIDER="$(tf_out wif_provider)"
[[ -z "$DEPLOYER_SA" ]] && DEPLOYER_SA="$(tf_out sa_deployer_email)"

set_secret() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then echo "  - skip $name (no value)"; return; fi
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO" --body -
  echo "  + secret $name"
}

echo "Setting secrets on $REPO ..."
set_secret WIF_PROVIDER "$WIF_PROVIDER"
set_secret DEPLOYER_SA "$DEPLOYER_SA"
set_secret GCP_PROJECT_DEV "$PROJECT_DEV"
set_secret GCP_PROJECT_PRD "$PROJECT_PRD"
set_secret ASTRO_API_TOKEN "$ASTRO_TOKEN"
set_secret ASTRO_DEPLOYMENT_ID_DEV "$ASTRO_DEV"
set_secret ASTRO_DEPLOYMENT_ID_PRD "$ASTRO_PRD"

gh variable set GCP_REGION --repo "$REPO" --body "$REGION" >/dev/null
echo "  + variable GCP_REGION = $REGION"
echo "Done."
