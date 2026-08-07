#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd aws
require_cmd curl
require_cmd ssh
require_seoul_region
require_env KEY_NAME
validate_ssh_cidr
require_non_root_identity

log "Checking key pair exists in Seoul region..."
aws_cli ec2 describe-key-pairs --key-names "$KEY_NAME" --output json >/dev/null

INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
log "Checking selected instance type is currently marked free-tier-eligible by EC2 API..."
if ! aws_cli ec2 describe-instance-types \
  --filters Name=free-tier-eligible,Values=true \
  --query 'InstanceTypes[].InstanceType' --output text | tr '\t' '\n' | grep -Fxq "$INSTANCE_TYPE"; then
  die "$INSTANCE_TYPE is not marked free-tier-eligible for this account/region. Choose an eligible micro type and re-run."
fi

cat <<MSG
[B6-1] Preflight technical checks passed.
[B6-1] HUMAN COST GATE STILL REQUIRED:
  1) Open AWS Billing / Free Tier and confirm your account plan/credits.
  2) Confirm you accept any possible EC2/EBS/public-IPv4 charges.
  3) Only then run provisioning with CONFIRM_CREATE=B6-1.
MSG
