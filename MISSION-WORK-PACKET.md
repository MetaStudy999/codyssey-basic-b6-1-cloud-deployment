# B6-1 Mission Work Packet — Cloud Deployment

## 1. Identity

- Mission ID: `B6-1`
- Mission Title: 내가 만든 웹사이트를 인터넷에 올려 누구나 쓰게 하기
- Mission Repository: `MetaStudy999/codyssey-basic-b6-1-cloud-deployment`
- Workcell: `Wave 20260808-01 / Chat 12`
- Started At: `2026-08-08T04:39:00+09:00`
- Official Requirement: `required`

## 2. Control Tower Baseline

- Control Tower Repository: `MetaStudy999/codyssey-basic`
- Frozen Baseline SHA: `0d1581b3e82366988f57e1d76da311c028b8e15e`
- Active Wave: `config/waves/20260808-01.yaml`
- Starter Packet: `docs/00-governance/work-packets/b6-1.md`
- Baseline Rule: Workcell 동안 고정한다. Control Tower는 READ ONLY다.

Required frozen context checked:

- `AGENTS.md`
- `docs/00-governance/multi-agent-mission-engineering.md`
- `docs/00-governance/source-discovery-fallback-protocol.md`
- `docs/00-governance/parallel-mission-execution.md`
- `config/missions.yaml`
- B6-1 mission index

## 3. Read / Write Boundary

### READ

- frozen Control Tower baseline
- 현재 B6-1 Mission Repository
- B6-1 Mission / Evaluation sources

### WRITE

- `MetaStudy999/codyssey-basic-b6-1-cloud-deployment`의 `mission/b6-1` branch만

### DO NOT WRITE

- `MetaStudy999/codyssey-basic`
- 다른 Mission Repository

## 4. Source Inventory

| Source Candidate | Type | State | Location | Notes |
|---|---|---|---|---|
| Mission original | PDF | `VALID` | `b6-1-mission.pdf` | 8 pages, repository blob SHA `43ff95e31d3ad78b6d3e2dfb64cb658252ef3f7e`; provided PDF의 Git blob SHA도 동일 |
| Mission transcription | Markdown | `DUPLICATE` | `b6-1-mission.md` | PDF를 Markdown 구조로 옮긴 문서. 확인한 요구사항에 충돌 없음 |
| Evaluation | Markdown | `VALID` | `b6-1-evaluation.md` | 4개 평가 항목과 세부 문항이 실질적으로 존재하며 Mission과 충돌 없음 |
| Operation material | Control Tower | `VALID` | frozen `config/missions.yaml`, mission index | B6-1 required, current gate G1_SOURCE |

- Source Mode: `FULL SOURCE`
- Source Confidence: `HIGH`
- Source Gaps: `NONE` for requirement extraction
- Runtime Gap: 실제 AWS 계정/리소스/외부 접속/cleanup 상태는 아직 확인되지 않음 (`NEEDS-RUNTIME`)

## 5. Mission Contract

### Goal

AWS 서울 리전에서 VPC 기반 public network와 EC2 웹 서버를 최소 권한·최소 노출 원칙으로 구성하고, 외부 접속·설계·트러블슈팅·정리 증거를 남긴다.

### Required Deliverables

- [x] `docs/architecture.(png|pdf)` 1개
- [ ] 외부 접속 검증 방식 A 또는 B와 URL/IP를 README에 기록
- [ ] 외부 접속 결과 스크린샷 1장 이상
- [ ] `docs/troubleshooting.(md|pdf)` 1개, 실제 사례 최소 1건
- [x] `docs/cleanup-checklist.md` 1개

### Required Functions / Behaviors

- [ ] VPC 1개
- [ ] Public Subnet 1개
- [ ] Internet Gateway 연결
- [ ] Route Table `0.0.0.0/0 -> IGW`
- [ ] Public Subnet instance outbound internet 통신
- [ ] EC2 1대 + SSH 접속
- [ ] Nginx 등 web server 실행
- [ ] instance localhost HTTP 200
- [ ] Security Group 최소 inbound: HTTP 80 public, SSH 22 learner/designated CIDR only
- [ ] `0.0.0.0/0` 전체 port rule 금지
- [ ] IAM user/role 1개, EC2/VPC/SG 실습 범위 최소권한, `AdministratorAccess` 금지
- [ ] 외부 검증: Method B `GET http://<public-ip>/health` 200 + fixed response를 기본 선택
- [ ] cleanup 시 EC2/EBS/EIP/IGW/VPC 최소 5종을 추적하고 완료/N/A 근거 기록

### Constraints

- Cloud provider: `Amazon Web Services (AWS)`
- Region: `ap-northeast-2` (Seoul)
- root account로 실습하지 않음
- source가 요구하는 Free Tier 범위/비용 경계를 Human이 생성 전에 확인
- micro 급 instance 권장, Ubuntu LTS 또는 Amazon Linux 계열
- secret, access key, private key, credential은 repository에 commit하지 않음
- 실제 Cloud 생성/삭제/권한 변경은 Human Runtime Authority

### Explicit Non-scope

- HTTPS: bonus
- Docker deployment: bonus
- NAT Gateway / ALB / RDS: 기본 요구 아님
- multi-instance scaling: 평가 설명 문항에는 포함되나 기본 배포 산출물은 아님

## 6. Requirement Traceability

| ID | Requirement | Source | Location | Implementation | Test | Evidence | Status |
|---|---|---|---|---|---|---|---|
| REQ-B6-1-001 | VPC/Public Subnet/IGW/route 구성 | Mission PDF | §4.1 | automation prepared + runtime pending | AWS describe | architecture + console/CLI | NEEDS-RUNTIME |
| REQ-B6-1-002 | EC2/SSH/web server/localhost 200 | Mission PDF | §4.2 | automation prepared | SSH/curl | runtime capture | NEEDS-RUNTIME |
| REQ-B6-1-003 | SG 80 public, 22 restricted, all-port public 금지 | Mission PDF | §4.3 | automation prepared | SG inspect | runtime capture | NEEDS-RUNTIME |
| REQ-B6-1-004 | IAM least privilege, no AdministratorAccess | Mission PDF | §4.4 | policy template tested + Human attach | IAM inspect | runtime capture | NEEDS-RUNTIME |
| REQ-B6-1-005 | 외부 검증 A/B | Mission PDF | §4.5 | Method B `/health` prepared | external curl | screenshot | NEEDS-RUNTIME |
| REQ-B6-1-006 | cleanup / cost safety | Mission PDF | §4.6, §7 | cleanup script + checklist tested | resource inventory | cleanup checklist | NEEDS-RUNTIME |
| REQ-B6-1-007 | architecture diagram | Mission PDF | §2.1 | target diagram | visual review | `docs/architecture.pdf` | TESTED |
| REQ-B6-1-008 | troubleshooting actual case | Mission PDF | §2.3 | runtime template prepared | hypothesis -> verification | report | NEEDS-RUNTIME |

## 7. Evaluation Mapping

| Evaluation ID | Criterion | Related Requirement | Validation | Evidence | Status |
|---|---|---|---|---|---|
| EVA-1 | 인프라 구성/외부 접속/cleanup | 001-006 | AWS CLI + SSH + external curl | screenshots + checklist | NEEDS-RUNTIME |
| EVA-2 | 구조/설계 설명 | 001,003,005,006,007 | architecture/readme explanation | architecture + learning notes | NEEDS-RUNTIME |
| EVA-3 | 핵심 원리 이해 | 001,003,004,008 | explanation checklist | learning notes + report | NEEDS-RUNTIME |
| EVA-4 | 문제 해결/확장 대응 | 004,008 | troubleshooting + extension explanation | report + learning notes | NEEDS-RUNTIME |

## 8. Repository Baseline

- Default Branch: `main`
- Baseline Commit: `437817738c5ae83dbc3a66a5db99fa5b237dd3f1`
- Work Branch: `mission/b6-1`
- Existing Tests: `NO`

Baseline inventory:

```text
README.md
b6-1-evaluation.md
b6-1-mission.md
b6-1-mission.pdf
```

Existing implementation:

- Source documents: present
- IaC/provision scripts: missing
- architecture deliverable: missing
- troubleshooting report: missing
- cleanup checklist: missing
- evidence: missing
- deployed AWS runtime: unverified

## 9. Mission-specific TOC

```text
B6-1
├── Source / Evaluation
├── Account / Region / Cost Boundary
├── VPC / Public Subnet
├── Internet Gateway / Route Table
├── EC2 / Nginx
├── Security Group
├── IAM Least Privilege
├── External /health Verification
├── Architecture
├── Troubleshooting
├── Cleanup / Billing Safety
├── Evidence
├── Learning
└── Handoff
```

## 10. Engineering Plan

- ROLE: B6-1 Cloud Deployment builder/reviewer
- GOAL: 최소 충분 AWS lab harness를 만들고 실제 Cloud Runtime만 Human에게 남긴다.
- SCOPE: shell automation, IAM policy template, docs, static tests, evidence plan
- OUTPUT CONTRACT: source-traceable files + tests + exact NEEDS-RUNTIME boundary
- STOP CONDITION: AI 가능한 G2-G4/G7 완료 후 Cloud runtime/evidence 없이는 PASS 주장하지 않음

Harness:

- Git boundary: `mission/b6-1`
- Test: shell syntax, JSON parse, repository contract/static requirement checks
- Secret boundary: `.env`, `*.pem`, credentials, access key commit 금지
- Evidence boundary: planned/example != actual

## 11. Agent Routing

- Orchestrator / Integrator: `ChatGPT`
- Primary Builder: `ChatGPT` in this connected environment; no second builder needed
- Independent Reviewer: one bounded review after static tests
- Multimodal Source Review: completed by PDF extraction/visual source context
- Runtime Authority: `Human`

## 12. Dependency / Drift Check

- Upstream Dependency: `NONE` (official source does not require a specific prior mission artifact)
- Related Mission: prior web missions are reusable but not required
- Control Tower Drift: `NONE` for frozen baseline execution
- Source Drift: `NONE` observed
- Action: `CONTINUE`

## 13. Test Plan

| Test | Requirement | Method | Expected | Status |
|---|---|---|---|---|
| Shell syntax | scripts | `bash -n` | all pass | PASS |
| IAM policy JSON | REQ-004 | JSON parse + action checks | valid/no admin | PASS |
| Static contract | REQ-001..008 | `python tests/static_check.py` | pass | PASS |
| AWS preflight | REQ-004/constraints | Human `scripts/preflight.sh` | non-root, Seoul, key/cidr valid | NEEDS-RUNTIME |
| Network/EC2 | REQ-001..003 | AWS CLI + SSH/curl | required resources/200 | NEEDS-RUNTIME |
| External health | REQ-005 | external curl | HTTP 200 + `OK` | NEEDS-RUNTIME |
| Cleanup | REQ-006 | cleanup + inventory | zero tracked resources/N/A | NEEDS-RUNTIME |

## 14. Runtime Plan

| Runtime Check | AI 가능 | Human 필요 | Evidence | Status |
|---|---|---|---|---|
| AWS account/free-tier/cost boundary | No | Yes | Billing/Free Tier confirmation | NEEDS-RUNTIME |
| IAM operator/role actual permissions | No | Yes | IAM screenshot/CLI | NEEDS-RUNTIME |
| Cloud resource creation | No | Yes | CLI/console output | NEEDS-RUNTIME |
| SSH/outbound/localhost 200 | No | Yes | terminal screenshot/text | NEEDS-RUNTIME |
| external `/health` | No | Yes | screenshot | NEEDS-RUNTIME |
| cleanup/billing | No | Yes | checklist + inventory | NEEDS-RUNTIME |

## 15. Evidence Plan

| Evidence | Requirement/Evaluation | Capture Method | Location | Status |
|---|---|---|---|---|
| architecture | REQ-007/EVA-2 | generated diagram, reconcile with runtime | `docs/architecture.pdf` | TESTED |
| external health | REQ-005/EVA-1 | browser/curl screenshot | `evidence/` | NEEDS-RUNTIME |
| network/SG | REQ-001/003 | console or CLI screenshot | `evidence/` | NEEDS-RUNTIME |
| IAM | REQ-004 | console/CLI screenshot | `evidence/` | NEEDS-RUNTIME |
| troubleshooting | REQ-008 | actual logs/commands | `docs/troubleshooting.md` | NEEDS-RUNTIME |
| cleanup | REQ-006 | inventory/billing screenshot + checklist | `docs/cleanup-checklist.md`, `evidence/` | NEEDS-RUNTIME |

## 16. Completion Gates

| Gate | Exit Condition | Status |
|---|---|---|
| G1 SOURCE | source state/mode/gap/provenance confirmed | `PASS` |
| G2 BUILD | required non-runtime implementation exists | `PASS` |
| G3 TEST | static/automatable tests pass | `PASS` |
| G4 REVIEW | BLOCKER=0, MAJOR=0 for prepared harness | `PASS` |
| G5 RUNTIME | actual AWS checks complete | `NEEDS-RUNTIME` |
| G6 EVIDENCE | actual required evidence complete | `NEEDS-RUNTIME` |
| G7 LEARN | source-aligned learning notes complete | `PASS` |
| G8 MERGE | Mission PR/merge complete after runtime/evidence | TODO |

## 16.1 G3/G4 Actual Result

AI-verifiable checks executed against byte-identical local copies of the branch blobs:

```text
python3 tests/static_check.py                         -> PASS
for f in scripts/*.sh; do bash -n "$f"; done         -> PASS
python3 -m json.tool iam/b6-1-operator-policy.json   -> PASS
```

Branch blob SHAs were compared with local `git hash-object` values, including `docs/architecture.pdf`, before accepting these results.

Bounded review result:

- BLOCKER: `0`
- MAJOR: `0` remaining in the AI-prepared harness
- Corrected during review: raw `file://` EC2 user-data handling, dynamic AMI root-device lookup, cleanup dependency retries, narrower explicit EC2 Describe actions, and T3 `CpuCredits=standard` cost control.
- External independent agent was not invoked in this environment; this is recorded rather than falsely claiming an independent audit. G5/G6 remain the decisive Human Runtime gates.

## 17. STOP Rule

Mission complete only after required source/evaluation, BLOCKER=0, MAJOR=0, tests, actual AWS runtime, required evidence, learning material, and Mission PR merge are all satisfied. Bonus HTTPS/Docker and production-grade expansion do not delay completion.

## 18. Handoff Contract

After runtime/evidence and final review, create `HANDOFF.md` and `mission-result.yaml`. Do not update Control Tower directly.
