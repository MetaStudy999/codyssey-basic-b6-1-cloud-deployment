# B6-1 Troubleshooting Report

> Status: `NEEDS-RUNTIME`. 아래는 실제 AWS 실행에서 채우는 증빙 양식이다. 예시 문구를 실제 수행 결과로 오인하지 않는다.

## Incident 1 — <실제 문제 한 줄 요약>

### 1. 증상

- 발생 시각:
- 실행한 요청/명령:
- 관측된 오류/timeout/status:

### 2. 가설

한 번에 하나의 가설만 적는다.

- 가설 A:
- 이 가설을 먼저 확인하는 이유:

### 3. 검증

```text
# 실제 실행 명령과 실제 출력의 핵심 부분을 붙인다.
```

권장 점검 순서:

1. Route Table: `0.0.0.0/0 -> IGW`
2. Security Group: 80 public, 22 learner CIDR only
3. EC2 public IPv4 / DNS 존재
4. EC2 상태 + Nginx process/log

### 4. 조치

- 실제 변경한 설정:
- 변경 범위를 최소화한 이유:

### 5. 결과

```text
# 조치 후 실제 재검증 명령/출력
```

### 6. 재발 방지

- checklist/automation에 추가한 예방 조치:

## No-natural-error controlled option

실습 중 자연 발생 오류가 없을 때만, Human이 원하면 **HTTP 80 rule을 일시 제거하여 외부 `/health` 실패를 재현한 뒤 같은 rule을 즉시 복구**하는 단일 가설 실습을 할 수 있다. SSH rule은 건드리지 않는다. 수행했다면 실제 명령/시간/출력을 위 Incident 1에 기록한다.
