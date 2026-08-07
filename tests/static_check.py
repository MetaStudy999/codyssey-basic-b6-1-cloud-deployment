from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require(path: str) -> Path:
    p = ROOT / path
    assert p.exists(), f"missing required path: {path}"
    return p


def read(path: str) -> str:
    return require(path).read_text(encoding="utf-8")


# Mission deliverable scaffolding
for path in [
    "MISSION-WORK-PACKET.md",
    "AGENTS.md",
    "docs/architecture.pdf",
    "docs/troubleshooting.md",
    "docs/cleanup-checklist.md",
    "docs/runtime-guide.md",
    "docs/learning.md",
    "evidence/README.md",
    "iam/b6-1-operator-policy.json",
    "scripts/preflight.sh",
    "scripts/provision.sh",
    "scripts/verify.sh",
    "scripts/cleanup.sh",
    "scripts/resource-audit.sh",
]:
    require(path)

# Shell syntax
for script in sorted((ROOT / "scripts").glob("*.sh")):
    subprocess.run(["bash", "-n", str(script)], check=True)

# IAM policy must be parseable and not administrator-wide.
policy = json.loads(read("iam/b6-1-operator-policy.json"))
policy_text = json.dumps(policy)
assert "AdministratorAccess" not in policy_text
assert "ap-northeast-2" in policy_text
assert "ec2:RunInstances" in policy_text
assert "ec2:CreateVpc" in policy_text
assert "iam:*" not in policy_text

provision = read("scripts/provision.sh")
assert "--destination-cidr-block 0.0.0.0/0 --gateway-id" in provision
assert "--protocol tcp --port 80 --cidr 0.0.0.0/0" in provision
assert "--protocol tcp --port 22 --cidr \"$SSH_CIDR\"" in provision
assert "--port 22 --cidr 0.0.0.0/0" not in provision
assert "CONFIRM_CREATE" in provision
assert "DeleteOnTermination" in provision
assert "Encrypted" in provision

lib = read("scripts/lib.sh")
assert '[[ "$SSH_CIDR" != "0.0.0.0/0" ]]' in lib
assert '[[ "$AWS_REGION" == "ap-northeast-2" ]]' in lib
assert ':root' in lib

cleanup = read("scripts/cleanup.sh")
for token in ["terminate-instances", "delete-volume", "delete-internet-gateway", "delete-subnet", "delete-vpc"]:
    assert token in cleanup, f"cleanup missing {token}"
assert "CONFIRM_CLEANUP" in cleanup

readme = read("README.md")
assert "Method B" in readme
assert "/health" in readme
assert "ap-northeast-2" in readme
assert "NEEDS-RUNTIME" in readme

# Secret patterns should not appear in tracked text files.
secret_patterns = [
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
]
for p in ROOT.rglob("*"):
    if not p.is_file() or ".state" in p.parts or p.suffix.lower() == ".pdf":
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    for pattern in secret_patterns:
        assert not pattern.search(text), f"possible secret in {p.relative_to(ROOT)}"

pdf = require("docs/architecture.pdf").read_bytes()
assert pdf.startswith(b"%PDF-")
assert b"Internet Gateway" in pdf
assert b"Public Subnet" in pdf
assert b"Security Group" in pdf
assert b"EC2" in pdf

print("B6-1 static checks: PASS")
