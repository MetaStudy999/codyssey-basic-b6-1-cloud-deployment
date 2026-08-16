#!/usr/bin/env bash
# B6-1 R01 verification-only helper.
# Reference mode: verify files only.
# Runtime mode: read-only AWS describe/curl checks. No create/update/delete actions.

set -u

PASS=0
FAIL=0
MODE="${1:-reference}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROUND_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
info() { echo "[INFO] $1"; }

for file in \
  "$ROUND_DIR/REFERENCE-BUILD.md" \
  "$ROUND_DIR/reference/nginx/default.conf" \
  "$ROUND_DIR/reference/iam/least-privilege.md" \
  "$ROUND_DIR/docs/architecture.mmd" \
  "$ROUND_DIR/docs/troubleshooting.md" \
  "$ROUND_DIR/docs/cleanup-checklist.md"; do
    [ -f "$file" ] && pass "file exists: ${file#$ROUND_DIR/}" || fail "file missing: ${file#$ROUND_DIR/}"
done

if grep -Eq 'listen 80' "$ROUND_DIR/reference/nginx/default.conf" && grep -Eq 'location = /health' "$ROUND_DIR/reference/nginx/default.conf"; then
  pass "Nginx reference listens on 80 and exposes /health"
else
  fail "Nginx reference port/health configuration"
fi

if grep -Eq '0\.0\.0\.0/0.*IGW|0\.0\.0\.0/0.*Internet Gateway' "$ROUND_DIR/docs/architecture.mmd"; then
  pass "architecture source contains public default route"
else
  fail "architecture source default route"
fi

if [ "$MODE" = "--runtime" ] || [ "$MODE" = "runtime" ]; then
  if ! command -v aws >/dev/null 2>&1; then
    fail "AWS CLI is required for runtime verify"
  else
    pass "AWS CLI command"
  fi

  required_vars=(AWS_REGION B6_VPC_ID B6_SUBNET_ID B6_IGW_ID B6_ROUTE_TABLE_ID B6_SG_ID B6_INSTANCE_ID B6_PUBLIC_IP)
  missing=0
  for name in "${required_vars[@]}"; do
    if [ -n "${!name:-}" ]; then
      pass "runtime variable set: $name"
    else
      fail "runtime variable missing: $name"
      missing=$((missing + 1))
    fi
  done

  if command -v aws >/dev/null 2>&1 && [ "$missing" -eq 0 ]; then
    if aws ec2 describe-vpcs --region "$AWS_REGION" --vpc-ids "$B6_VPC_ID" --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -qx "$B6_VPC_ID"; then
      pass "VPC exists"
    else
      fail "VPC exists"
    fi

    subnet_vpc=$(aws ec2 describe-subnets --region "$AWS_REGION" --subnet-ids "$B6_SUBNET_ID" --query 'Subnets[0].VpcId' --output text 2>/dev/null || true)
    [ "$subnet_vpc" = "$B6_VPC_ID" ] && pass "Subnet belongs to VPC" || fail "Subnet belongs to VPC"

    igw_vpc=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" --internet-gateway-ids "$B6_IGW_ID" --query 'InternetGateways[0].Attachments[0].VpcId' --output text 2>/dev/null || true)
    [ "$igw_vpc" = "$B6_VPC_ID" ] && pass "Internet Gateway attached to VPC" || fail "Internet Gateway attachment"

    route_target=$(aws ec2 describe-route-tables --region "$AWS_REGION" --route-table-ids "$B6_ROUTE_TABLE_ID" --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId | [0]" --output text 2>/dev/null || true)
    [ "$route_target" = "$B6_IGW_ID" ] && pass "0.0.0.0/0 route points to IGW" || fail "public default route"

    http_rule=$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$B6_SG_ID" --query "SecurityGroups[0].IpPermissions[?IpProtocol=='tcp' && FromPort==\`80\` && ToPort==\`80\`].IpRanges[].CidrIp" --output text 2>/dev/null || true)
    echo "$http_rule" | tr '\t' '\n' | grep -qx '0.0.0.0/0' && pass "SG allows HTTP 80 from 0.0.0.0/0" || fail "SG HTTP rule"

    all_open=$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$B6_SG_ID" --query "SecurityGroups[0].IpPermissions[?IpProtocol=='-1'].IpRanges[].CidrIp" --output text 2>/dev/null || true)
    if echo "$all_open" | tr '\t' '\n' | grep -qx '0.0.0.0/0'; then
      fail "SG must not allow all traffic from 0.0.0.0/0"
    else
      pass "SG has no all-traffic 0.0.0.0/0 rule"
    fi

    instance_state=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || true)
    [ "$instance_state" = "running" ] && pass "EC2 instance running" || fail "EC2 instance running ($instance_state)"

    actual_public_ip=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$B6_INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null || true)
    [ "$actual_public_ip" = "$B6_PUBLIC_IP" ] && pass "EC2 Public IPv4 matches" || fail "EC2 Public IPv4 matches"

    if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 10 "http://$B6_PUBLIC_IP/health" | grep -qx 'OK'; then
      pass "external /health returns OK"
    else
      fail "external /health returns OK"
    fi
  fi
fi

echo
printf 'Result: %d PASS / %d FAIL\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
