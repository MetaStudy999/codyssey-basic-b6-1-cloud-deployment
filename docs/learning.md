# B6-1 Learning Notes

## 1. Request path

`Internet client -> Internet Gateway -> VPC route table -> Public Subnet -> Security Group -> EC2:80 -> Nginx`

A Public Subnet is not public merely because of its name. For this mission, the subnet needs a route whose default destination `0.0.0.0/0` points to the Internet Gateway, and the instance needs a public IPv4 address. The Security Group must then permit the intended inbound traffic.

## 2. VPC, Subnet, Route Table, Internet Gateway

- **VPC (Virtual Private Cloud)**: isolated logical network boundary.
- **Subnet**: a CIDR slice inside the VPC where resources are placed.
- **Route Table**: decides where packets for destination networks go.
- **Internet Gateway (IGW)**: VPC attachment that provides a path between internet-routable public addresses and the internet when routing/security also allow it.

Why `0.0.0.0/0 -> IGW`? `0.0.0.0/0` means any IPv4 destination not matched by a more specific route. Without that path, internet-bound traffic has no IGW route.

## 3. Security Group vs IAM

- **Security Group (SG)** controls network traffic to/from resources: who can reach which protocol/port.
- **IAM (Identity and Access Management)** controls AWS API/console authorization: who may create/read/change/delete resources.

For B6-1:

- HTTP 80 is public because the web service must be externally reachable.
- SSH 22 is limited to the learner/designated CIDR because management access does not need to be public to everyone.
- IAM policy is restricted to EC2/VPC/network actions in Seoul rather than administrator-wide authority.

## 4. Why not open SSH or DB ports to the world?

A global source `0.0.0.0/0` allows connection attempts from any internet host. Management/database ports normally serve a small administrator/service audience, so a specific source CIDR, VPN/bastion/private networking, or similar restricted path is safer.

## 5. Hypothesis-driven troubleshooting

When external HTTP fails, check in dependency order:

1. Route: does the subnet route `0.0.0.0/0` to the IGW?
2. SG: is TCP 80 allowed? Is SSH source correctly limited?
3. Addressing: does the EC2 instance actually have a public IPv4/DNS?
4. Server: is Nginx active, listening, and returning local HTTP 200? What do logs say?

Changing multiple settings at once destroys causality. A single hypothesis -> one verification -> one correction gives evidence of the root cause.

## 6. Scaling explanation for evaluation

If one EC2 instance becomes a bottleneck and the service must expand to two instances, the current single-instance endpoint needs a traffic distribution layer. An ALB (Application Load Balancer) can receive client traffic and route it to healthy instances, typically with health checks and multiple subnets/AZs. This is an evaluation explanation topic, not a required base resource for B6-1.

## 7. Cost / cleanup reasoning

Cloud resources can keep incurring cost after learning ends. Tagging and a dependency-aware cleanup order make deletion auditable. Terminate compute first, verify EBS/EIP state, remove dependent network objects, detach/delete IGW, then delete subnet/VPC. Finally inspect Billing / Free Tier.
