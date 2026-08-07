# B6-1 Human Runtime Guide

This guide is the Human Runtime boundary. AI-prepared files are not evidence of an AWS deployment.

## 0. Cost and account gate — before creation

1. Use a non-root IAM user/role.
2. Confirm AWS Billing / Free Tier status and remaining credits/allowance.
3. Confirm the selected EC2 type is shown as free-tier-eligible for the account/region.
4. Accept that actual eligibility/credits and public IPv4/EBS usage can affect cost.
5. Keep region fixed to `ap-northeast-2`.

Do **not** create resources until this is checked.

## 1. Local configuration

```bash
cp .env.example .env
# edit .env with your existing Seoul key pair name, your current public CIDR /32,
# and local private-key path. Do not commit .env or the key.
set -a
source .env
set +a
```

## 2. Preflight

```bash
bash scripts/preflight.sh
```

Normal: identity is not root, key pair exists, region is Seoul, selected instance type is eligible according to EC2 API.

## 3. Create only after cost/security confirmation

```bash
CONFIRM_CREATE=B6-1 bash scripts/provision.sh
```

The script creates/tag-tracks one VPC, public subnet, IGW, route table, SG, and one EC2 instance. Base harness does not allocate an Elastic IP, NAT Gateway, ALB, or RDS.

## 4. Verify

Wait for cloud-init/Nginx to finish, then:

```bash
bash scripts/verify.sh
```

For full SSH/local/outbound checks, `SSH_KEY_PATH` must point to the private key locally.

Expected runtime facts to capture:

- Route Table has `0.0.0.0/0 -> IGW`
- SG has `80/tcp <- 0.0.0.0/0`
- SG has `22/tcp <- your SSH_CIDR`, never `0.0.0.0/0`
- SSH succeeds
- `curl http://localhost` succeeds on EC2
- `curl https://example.com` succeeds on EC2
- external `GET http://<public-ip>/health` returns HTTP 200 and `OK`

## 5. Required evidence

At minimum capture and add to `evidence/`:

- external `/health` result screenshot
- network/route screenshot or CLI capture
- Security Group inbound screenshot or CLI capture
- IAM policy/identity proof without secrets
- actual troubleshooting evidence
- cleanup/resource-audit proof

Update README with the actual public URL/IP while it is valid. Never add private keys/access keys.

## 6. Troubleshooting

If verification fails, use `docs/troubleshooting.md`. Change one hypothesis at a time. Do not open SSH to the world as a quick fix.

## 7. Cleanup after evidence

```bash
CONFIRM_CLEANUP=B6-1 bash scripts/cleanup.sh
bash scripts/resource-audit.sh
```

Complete `docs/cleanup-checklist.md`, then check Billing / Free Tier. The mission remains `NEEDS-RUNTIME` until these actual checks and evidence are complete.
