# B6-1 Evidence

Do not put fabricated/example output here. Add only actual runtime evidence.

Suggested names:

- `01-external-health.png` — Method B `/health` HTTP 200 + `OK`
- `02-route-table.png` — `0.0.0.0/0 -> IGW`
- `03-security-group.png` — 80 public, 22 learner CIDR only
- `04-iam-least-privilege.png` — operator policy/role without secrets
- `05-ssh-local-outbound.png` — SSH, localhost 200, outbound curl
- `06-troubleshooting.png` — actual error/verification result if useful
- `07-cleanup-audit.png` — post-cleanup resource audit
- `08-billing-check.png` — optional/recommended Billing/Free Tier confirmation

Public IP addresses are acceptable evidence metadata; credentials/private keys are not.
