#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

[[ "${CONFIRM_CREATE:-}" == "B6-1" ]] || die "Refusing cloud creation. Run only after cost/security review with CONFIRM_CREATE=B6-1"
require_cmd aws
require_seoul_region
require_env KEY_NAME
validate_ssh_cidr
require_non_root_identity

INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
VPC_CIDR="${VPC_CIDR:-10.61.0.0/16}"
SUBNET_CIDR="${SUBNET_CIDR:-10.61.1.0/24}"
NAME_PREFIX="${NAME_PREFIX:-codyssey-b6-1}"

ensure_state_dir
set_state AWS_REGION "$AWS_REGION"
set_state PROJECT_TAG "$PROJECT_TAG"
set_state INSTANCE_TYPE "$INSTANCE_TYPE"
set_state SSH_CIDR "$SSH_CIDR"
set_state KEY_NAME "$KEY_NAME"

log "Creating VPC..."
VPC_ID="$(aws_cli ec2 create-vpc --cidr-block "$VPC_CIDR" --query 'Vpc.VpcId' --output text)"
set_state VPC_ID "$VPC_ID"
aws_cli ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value="${NAME_PREFIX}-vpc" Key=Project,Value="$PROJECT_TAG"
aws_cli ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support '{"Value":true}'
aws_cli ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'

log "Creating public subnet..."
SUBNET_ID="$(aws_cli ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR" --query 'Subnet.SubnetId' --output text)"
set_state SUBNET_ID "$SUBNET_ID"
aws_cli ec2 create-tags --resources "$SUBNET_ID" --tags Key=Name,Value="${NAME_PREFIX}-public-subnet" Key=Project,Value="$PROJECT_TAG"
aws_cli ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch

log "Creating and attaching Internet Gateway..."
IGW_ID="$(aws_cli ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)"
set_state IGW_ID "$IGW_ID"
aws_cli ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value="${NAME_PREFIX}-igw" Key=Project,Value="$PROJECT_TAG"
aws_cli ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

log "Creating route table and default route..."
ROUTE_TABLE_ID="$(aws_cli ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)"
set_state ROUTE_TABLE_ID "$ROUTE_TABLE_ID"
aws_cli ec2 create-tags --resources "$ROUTE_TABLE_ID" --tags Key=Name,Value="${NAME_PREFIX}-public-rt" Key=Project,Value="$PROJECT_TAG"
aws_cli ec2 create-route --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
ROUTE_ASSOC_ID="$(aws_cli ec2 associate-route-table --route-table-id "$ROUTE_TABLE_ID" --subnet-id "$SUBNET_ID" --query 'AssociationId' --output text)"
set_state ROUTE_ASSOC_ID "$ROUTE_ASSOC_ID"

log "Creating security group with HTTP public and SSH restricted..."
SG_ID="$(aws_cli ec2 create-security-group --group-name "${NAME_PREFIX}-sg" --description 'Codyssey B6-1 web security group' --vpc-id "$VPC_ID" --query GroupId --output text)"
set_state SG_ID "$SG_ID"
aws_cli ec2 create-tags --resources "$SG_ID" --tags Key=Name,Value="${NAME_PREFIX}-sg" Key=Project,Value="$PROJECT_TAG"
aws_cli ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
aws_cli ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$SSH_CIDR" >/dev/null

log "Resolving latest Ubuntu 24.04 LTS amd64 AMI from Canonical..."
AMI_ID="$(aws_cli ec2 describe-images --owners 099720109477 \
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' 'Name=state,Values=available' \
  --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId' --output text)"
[[ "$AMI_ID" != "None" && -n "$AMI_ID" ]] || die "Could not resolve Ubuntu 24.04 AMI"
set_state AMI_ID "$AMI_ID"

ROOT_DEVICE_NAME="$(aws_cli ec2 describe-images --image-ids "$AMI_ID" --query 'Images[0].RootDeviceName' --output text)"
[[ -n "$ROOT_DEVICE_NAME" && "$ROOT_DEVICE_NAME" != "None" ]] || die "Could not resolve AMI root device name"
set_state ROOT_DEVICE_NAME "$ROOT_DEVICE_NAME"

log "Launching EC2 instance $INSTANCE_TYPE..."
INSTANCE_ID="$(aws_cli ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --user-data "file://${SCRIPT_DIR}/user-data.sh" \
  --block-device-mappings "[{\"DeviceName\":\"${ROOT_DEVICE_NAME}\",\"Ebs\":{\"VolumeSize\":8,\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true,\"Encrypted\":true}}]" \
  --tag-specifications \
    "ResourceType=instance,Tags=[{Key=Name,Value=${NAME_PREFIX}-web},{Key=Project,Value=${PROJECT_TAG}}]" \
    "ResourceType=volume,Tags=[{Key=Name,Value=${NAME_PREFIX}-root},{Key=Project,Value=${PROJECT_TAG}}]" \
  --query 'Instances[0].InstanceId' --output text)"
set_state INSTANCE_ID "$INSTANCE_ID"

aws_cli ec2 wait instance-running --instance-ids "$INSTANCE_ID"
PUBLIC_IP="$(aws_cli ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
set_state PUBLIC_IP "$PUBLIC_IP"

cat <<MSG
[B6-1] Provisioning request completed.
Instance: $INSTANCE_ID
Public IP: $PUBLIC_IP
Health URL: http://$PUBLIC_IP/health
State: $STATE_FILE

Do not mark PASS yet. Wait for cloud-init, then run scripts/verify.sh and capture actual evidence.
MSG
