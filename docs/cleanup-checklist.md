# B6-1 Resource Cleanup Checklist

> Status: `NEEDS-RUNTIME`. 실제 삭제/미생성 여부를 확인한 뒤 체크한다. 생성하지 않은 항목은 `N/A — not created`로 근거를 남긴다.

## Required minimum tracking

- [ ] EC2 — instance terminated; instance ID/evidence:
- [ ] EBS — lab-tagged volumes deleted or DeleteOnTermination confirmed; evidence:
- [ ] Elastic IP — `N/A — base harness does not allocate EIP` 또는 Release evidence:
- [ ] Internet Gateway — detached and deleted; evidence:
- [ ] VPC — deleted; evidence:

## Related network resources

- [ ] Public Subnet deleted
- [ ] Route Table association removed and custom Route Table deleted
- [ ] Security Group deleted

## Conditional resources

- [ ] NAT Gateway — `N/A` unless manually created; if created, deleted
- [ ] ELB/ALB — `N/A` unless manually created; if created, deleted
- [ ] RDS — `N/A` unless manually created; if created, deleted

## Final audit

Run:

```bash
bash scripts/resource-audit.sh
```

Record the actual output or screenshot in `evidence/`.

- [ ] No B6-1 tagged EC2/VPC/network/EBS resources remain, except AWS-deleted history records
- [ ] AWS Billing / Free Tier page reviewed after cleanup
- [ ] Unexpected charge/resource: none, or documented below

### Final notes

- Cleanup date/time:
- AWS region: `ap-northeast-2`
- Reviewer:
- Evidence paths:
