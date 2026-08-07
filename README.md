# codyssey-basic-b6-1-cloud-deployment

Codyssey Basic B6-1 — **내가 만든 웹사이트를 인터넷에 올려 누구나 쓰게 하기**

> Current workcell status: **G1 PASS / AI-verifiable build in progress / AWS runtime NEEDS-RUNTIME**. No cloud deployment is claimed until actual AWS evidence exists.

## Source

- [Mission PDF](./b6-1-mission.pdf)
- [Mission Markdown](./b6-1-mission.md)
- [Evaluation](./b6-1-evaluation.md)
- [Mission Work Packet](./MISSION-WORK-PACKET.md)

## Mission decisions

| Item | B6-1 decision |
|---|---|
| Cloud | AWS |
| Region | `ap-northeast-2` (Seoul) |
| External verification | **Method B** — `GET http://<public-ip>/health` -> HTTP 200 + `OK` |
| Web server | Nginx on Ubuntu 24.04 LTS |
| Base instance | `t3.micro` default, but preflight must confirm current free-tier eligibility for the account/region |
| HTTP | TCP 80 from `0.0.0.0/0` |
| SSH | TCP 22 from learner/designated CIDR only; never `0.0.0.0/0` |
| IAM | non-root user/role, EC2/VPC/network action scope, no `AdministratorAccess` |
| Base EIP | not allocated; cleanup records EIP as N/A unless manually created |

## Repository layout

```text
.
├── AGENTS.md
├── MISSION-WORK-PACKET.md
├── iam/
│   └── b6-1-operator-policy.json
├── scripts/
│   ├── lib.sh
│   ├── preflight.sh
│   ├── provision.sh
│   ├── user-data.sh
│   ├── verify.sh
│   ├── cleanup.sh
│   └── resource-audit.sh
├── docs/
│   ├── architecture.pdf
│   ├── runtime-guide.md
│   ├── troubleshooting.md
│   ├── cleanup-checklist.md
│   └── learning.md
├── evidence/
│   └── README.md
└── tests/
    └── static_check.py
```

## Safety first

The mission source requires Free Tier operation and resource cleanup. Actual account eligibility and credits are account-specific, so **check AWS Billing / Free Tier before creation**. The scripts also refuse root identity, require Seoul region, require a restricted SSH CIDR, and require an explicit creation confirmation variable.

Never commit:

- AWS access key / secret key
- `.pem` private key
- populated `.env`
- local `.state/`

## AI-verifiable tests

```bash
python3 tests/static_check.py
for f in scripts/*.sh; do bash -n "$f"; done
python3 -m json.tool iam/b6-1-operator-policy.json >/dev/null
```

These tests validate the prepared repository only. They do not prove an AWS deployment.

## Human Runtime — minimum path

See [docs/runtime-guide.md](./docs/runtime-guide.md) for the detailed sequence.

```bash
cp .env.example .env
# edit .env locally; do not commit it
set -a && source .env && set +a

bash scripts/preflight.sh
CONFIRM_CREATE=B6-1 bash scripts/provision.sh

# after cloud-init/Nginx is ready
bash scripts/verify.sh

# capture evidence before cleanup
CONFIRM_CLEANUP=B6-1 bash scripts/cleanup.sh
bash scripts/resource-audit.sh
```

### External verification — Method B

After provisioning, the actual URL will be:

```text
http://<PUBLIC_IP>/health
```

Acceptance:

```text
HTTP 200
OK
```

Actual evaluated URL/IP: **NEEDS-RUNTIME — do not insert a guessed address.**

## Required deliverables/status

| Deliverable | Current status |
|---|---|
| `docs/architecture.pdf` | IMPLEMENTED as target design; reconcile after runtime |
| external access screenshot | NEEDS-RUNTIME |
| `docs/troubleshooting.md` | IMPLEMENTED template / actual incident NEEDS-RUNTIME |
| `docs/cleanup-checklist.md` | IMPLEMENTED / actual cleanup NEEDS-RUNTIME |
| IAM least-privilege template | IMPLEMENTED / actual attachment NEEDS-RUNTIME |
| AWS VPC/EC2/SG runtime | NEEDS-RUNTIME |

## Cleanup rule

Do not finish the lab by merely stopping an instance. The checklist tracks at least EC2, EBS, EIP, IGW, and VPC, plus subnet/route table/SG. The base harness does not create EIP/NAT/ALB/RDS; record those as N/A unless you created them manually.

## Learning

[docs/learning.md](./docs/learning.md) explains VPC/Subnet/Route/IGW, Security Group vs IAM, the external request path, hypothesis-driven troubleshooting, scaling discussion, and cleanup reasoning using this repository's design.
