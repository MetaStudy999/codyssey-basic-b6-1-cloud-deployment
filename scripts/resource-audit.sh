#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd aws
if [[ -f "$STATE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE"
fi
require_seoul_region

log "Instances tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-instances --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table
log "EBS volumes tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'Volumes[].[VolumeId,State,Size]' --output table
log "VPCs tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'Vpcs[].[VpcId,State,CidrBlock]' --output table
log "Subnets tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-subnets --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'Subnets[].[SubnetId,VpcId,CidrBlock]' --output table
log "Internet Gateways tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-internet-gateways --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'InternetGateways[].[InternetGatewayId,Attachments]' --output table
log "Security Groups tagged Project=$PROJECT_TAG"
aws_cli ec2 describe-security-groups --filters "Name=tag:Project,Values=$PROJECT_TAG" --query 'SecurityGroups[].[GroupId,VpcId,GroupName]' --output table
