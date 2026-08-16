# B6-1 R01 — Reference Build

## 목적

공식 Mission/Evaluation을 기준으로 **AWS VPC 안의 Public Subnet에 EC2 + Nginx를 배포하고, 필요한 포트만 여는 최소권한 웹 서비스 인프라**의 Reference Complete Path를 준비합니다.

현재 Phase A에서는 실제 AWS 리소스를 생성하지 않습니다. VPC/EC2/Security Group/IAM/Public IP/과금 리소스는 Phase C Runtime에서 사용자가 직접 생성·검증·정리합니다. 실제 Cloud 결과가 없는데 PASS/CLEAR로 기록하지 않습니다.

## Source of Truth

1. `b6-1-mission.pdf`
2. `b6-1-mission.md`
3. `b6-1-evaluation.md`

## Reference Golden Path

- Cloud: AWS
- Region 예시: `ap-northeast-2` — Runtime에서 실제 선택 Region 기록
- VPC CIDR 예시: `10.10.0.0/16`
- Public Subnet CIDR 예시: `10.10.1.0/24`
- Internet Gateway 1개
- Public Route: `0.0.0.0/0 → Internet Gateway`
- EC2: Ubuntu 계열 1대, Public Subnet 배치
- Public IPv4: 외부 접속에 필요
- Security Group:
  - TCP 80 ← `0.0.0.0/0`
  - TCP 22 ← **본인의 현재 Public IP/32만**
  - 전체 포트 `0.0.0.0/0` 허용 금지
- Web Server: Nginx
- `/`와 `/health` HTTP 200
- IAM: 실습에 필요한 EC2/VPC/Security Group 범위만, `AdministratorAccess` 금지
- Secret/credential/SSH Private Key는 GitHub·채팅·Evidence에 저장하지 않음

## Reference Complete Path

1. AWS Account/Region/IAM/Billing 안전 확인
2. VPC 생성
3. Public Subnet 생성
4. Internet Gateway 생성 및 VPC 연결
5. Route Table에 `0.0.0.0/0 → IGW`
6. Security Group 최소 포트 구성
7. EC2 생성 / Public IPv4 확인
8. SSH 접속
9. Nginx 설치/실행
10. instance localhost HTTP 200
11. instance outbound Internet 확인
12. 외부 브라우저 또는 `/health` HTTP 200
13. Architecture artifact 작성
14. Troubleshooting 1건 이상 기록
15. IAM 최소권한 재검토
16. Evidence 연결
17. Cleanup 후 과금 리소스 없음 확인
18. Evaluation 설명
19. CLEAR

## Reference Build 준비 대상

- Nginx Reference 설정
- Architecture Mermaid source
- IAM 최소권한 설계 체크
- Troubleshooting Runtime template
- Cleanup checklist
- Environment/verify helper
- Requirement/Evidence Mapping
- Evaluation Q&A
- Evidence Guide
- Beginner Guide
- CLEAR Checklist

## 현재 판정

**Reference Build 진행 중 / Mission 상태 ⬜ NOT STARTED / 실제 AWS Runtime 미시작**
