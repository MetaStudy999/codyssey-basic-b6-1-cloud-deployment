#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

[[ "${CONFIRM_CLEANUP:-}" == "B6-1" ]] || die "Refusing cleanup. Run with CONFIRM_CLEANUP=B6-1 after evidence capture."
require_cmd aws
load_state
require_seoul_region
require_non_root_identity

if [[ -n "${INSTANCE_ID:-}" ]]; then
  log "Terminating EC2 $INSTANCE_ID"
  aws_cli ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null || true
  aws_cli ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" || true
fi

# Delete any available EBS volumes tagged for this lab after instance termination.
for volume_id in $(aws_cli ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT_TAG" Name=status,Values=available --query 'Volumes[].VolumeId' --output text); do
  [[ -n "$volume_id" ]] || continue
  log "Deleting leftover EBS $volume_id"
  aws_cli ec2 delete-volume --volume-id "$volume_id"
done

if [[ -n "${SG_ID:-}" ]]; then
  log "Deleting security group $SG_ID"
  retry 12 5 aws_cli ec2 delete-security-group --group-id "$SG_ID"
fi

if [[ -n "${ROUTE_ASSOC_ID:-}" ]]; then
  aws_cli ec2 disassociate-route-table --association-id "$ROUTE_ASSOC_ID" || true
fi
if [[ -n "${ROUTE_TABLE_ID:-}" ]]; then
  log "Deleting route table $ROUTE_TABLE_ID"
  retry 6 3 aws_cli ec2 delete-route-table --route-table-id "$ROUTE_TABLE_ID"
fi
if [[ -n "${IGW_ID:-}" && -n "${VPC_ID:-}" ]]; then
  log "Detaching/deleting IGW $IGW_ID"
  retry 6 3 aws_cli ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
  retry 6 3 aws_cli ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
fi
if [[ -n "${SUBNET_ID:-}" ]]; then
  log "Deleting subnet $SUBNET_ID"
  retry 12 5 aws_cli ec2 delete-subnet --subnet-id "$SUBNET_ID"
fi
if [[ -n "${VPC_ID:-}" ]]; then
  log "Deleting VPC $VPC_ID"
  retry 12 5 aws_cli ec2 delete-vpc --vpc-id "$VPC_ID"
fi

log "No Elastic IP is created by the base harness. Record EIP as N/A unless you allocated one manually."
log "Run scripts/resource-audit.sh and complete docs/cleanup-checklist.md before declaring cleanup complete."
