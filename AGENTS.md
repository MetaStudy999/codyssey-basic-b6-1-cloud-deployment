# AGENTS.md — B6-1

## Scope
This repository is the B6-1 Mission Workcell. Work only on `MetaStudy999/codyssey-basic-b6-1-cloud-deployment` and prefer branch `mission/b6-1`.

## Source of Truth
1. `b6-1-mission.pdf`
2. `b6-1-mission.md`
3. `b6-1-evaluation.md`
4. `MISSION-WORK-PACKET.md`
5. README/docs/scripts/tests/evidence

Do not invent requirements outside the sources. Bonus HTTPS/Docker work must not delay the base mission.

## Safety / Runtime Boundary
- Never commit AWS credentials, access keys, secret keys, `.pem` private keys, or local state containing secrets.
- Do not create, mutate, or delete AWS resources without explicit Human Runtime execution.
- Do not claim AWS resources, external HTTP, IAM, cleanup, or Billing as PASS unless actual evidence exists.
- AWS lab region is `ap-northeast-2` per mission source.
- Root-account lab execution and `AdministratorAccess` are prohibited by the mission.
- SSH must never be opened to `0.0.0.0/0`; HTTP 80 may be public as required.

## Review Scope
First independent review is findings-only. Focus on BLOCKER/MAJOR:
- source requirement omissions
- unsafe SG/IAM/credential handling
- destructive cleanup bugs
- false PASS/runtime claims
- broken test/verification commands
- architecture/docs that contradict implementation

Do not request broad redesign, new frameworks, bonus features, or MINOR cleanup.

## Test Commands
```bash
python3 tests/static_check.py
for f in scripts/*.sh; do bash -n "$f"; done
python3 -m json.tool iam/b6-1-operator-policy.json >/dev/null
```

## Status Vocabulary
`TODO / IMPLEMENTED / TESTED / PASS / NEEDS-RUNTIME / BLOCKED`

## Stop Condition
Stop review when BLOCKER=0 and MAJOR=0 for AI-verifiable work. Runtime/evidence remain Human Authority until actually completed.
