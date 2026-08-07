#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd aws
require_cmd curl
load_state
require_seoul_region

: "${VPC_ID:?}" "${SUBNET_ID:?}" "${IGW_ID:?}" "${ROUTE_TABLE_ID:?}" "${SG_ID:?}" "${INSTANCE_ID:?}" "${PUBLIC_IP:?}"

log "VPC"
aws_cli ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].[VpcId,CidrBlock,State]' --output table
log "Subnet"
aws_cli ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].[SubnetId,CidrBlock,MapPublicIpOnLaunch,VpcId]' --output table
log "Route table"
aws_cli ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" --query 'RouteTables[0].Routes[].{Destination:DestinationCidrBlock,Gateway:GatewayId,State:State}' --output table
log "Internet Gateway"
aws_cli ec2 describe-internet-gateways --internet-gateway-ids "$IGW_ID" --query 'InternetGateways[0].Attachments' --output table
log "Security Group inbound"
aws_cli ec2 describe-security-groups --group-ids "$SG_ID" --query 'SecurityGroups[0].IpPermissions' --output json
log "Instance"
aws_cli ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,InstanceType,SubnetId,VpcId]' --output table

log "External Method B: GET /health"
BODY="$(curl --fail --silent --show-error --max-time 10 "http://${PUBLIC_IP}/health")" || die "External /health failed. Use docs/troubleshooting.md before changing multiple settings."
[[ "$(printf '%s' "$BODY" | tr -d '\r\n')" == "OK" ]] || die "Unexpected /health body: $BODY"
log "External /health PASS: HTTP 200, body OK"

if [[ -n "${SSH_KEY_PATH:-}" ]]; then
  [[ -f "$SSH_KEY_PATH" ]] || die "SSH_KEY_PATH does not exist: $SSH_KEY_PATH"
  chmod 600 "$SSH_KEY_PATH" 2>/dev/null || true
  log "SSH + instance-local checks"
  ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -i "$SSH_KEY_PATH" "ubuntu@${PUBLIC_IP}" \
    'set -e; systemctl is-active nginx; curl -fsS http://localhost/ >/dev/null; curl -fsS https://example.com >/dev/null; printf "LOCAL_HTTP=200 OUTBOUND=OK\\n"'
else
  log "SSH_KEY_PATH not set: SSH/local/outbound checks remain NEEDS-RUNTIME."
fi
