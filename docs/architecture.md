# Architecture and networking

## Design goals

The platform favors understandable AWS primitives, immutable releases, controlled blast radius, and explicit trade-offs. Each environment owns an independent VPC, ECS cluster/service, ECR repository, RDS instance, log group, alarms, and Terraform state object. The shared bootstrap root owns the state bucket and repository-scoped GitHub OIDC roles.

## Request and deployment paths

The runtime request path is `internet -> ALB -> target group -> ECS task`. The ALB is the only internet-facing application component. Fargate elastic network interfaces receive private addresses only. The database accepts PostgreSQL traffic only from the task security group.

The release path is `GitHub Actions -> OIDC role -> ECR -> ECS task definition -> ECS service`. Each image has an immutable commit-derived tag. Terraform establishes the service baseline; release automation owns later task definition revisions, so the ECS service ignores task-definition drift intentionally.

## Subnet tiers

Each VPC spans at least two Availability Zones and divides its `/16` into `/20` subnets:

| Tier | Route | Workloads |
|---|---|---|
| Public | Internet gateway | ALB and NAT gateways |
| Private application | NAT gateway | ECS Fargate tasks |
| Private database | No default internet route | RDS PostgreSQL |

Development routes both application subnets through one NAT gateway. This is cheaper but makes outbound connectivity dependent on one AZ. Production creates a NAT gateway and route table per AZ so each application subnet uses a local egress path.

## Network controls

- ALB security group: public TCP/80, optional TCP/443, and application-port egress within the VPC.
- Task security group: application-port ingress only from the ALB; outbound access supports ECR, CloudWatch, AWS APIs, and database connections.
- Database security group: TCP/5432 ingress only from tasks. The RDS instance is never public.
- ALB invalid-header dropping is enabled. Providing an ACM certificate creates an HTTPS listener and redirects HTTP to HTTPS.

Task egress is limited by port to HTTPS, VPC DNS, and PostgreSQL. A mature implementation should add ECR API/DKR, S3, CloudWatch Logs, Secrets Manager, and STS VPC endpoints, then constrain HTTPS destinations through a firewall or proxy.

## Compute and data

ECS uses Fargate with `awsvpc` networking, Container Insights, deployment circuit breaking, target-group health checks, and target tracking on CPU and memory. Production starts with two tasks across private subnets; dev starts with one.

RDS uses PostgreSQL 16, encrypted gp3 storage with storage autoscaling, forced SSL, automated backups, CloudWatch database logs, and an RDS-managed Secrets Manager password. Production enables Multi-AZ and deletion protection. The sample API is intentionally stateless and does not retrieve the database credential; that keeps the portfolio endpoint safe while demonstrating a database-ready network boundary.

## Terraform boundaries

- `network`: VPC, gateways, subnets, routes
- `ecr`: repository, scanning, encryption, lifecycle
- `ecs_service`: cluster, IAM, ALB, tasks, service, scaling, logs, alarms
- `rds`: subnet/parameter groups, security group, PostgreSQL
- `platform`: composes an environment from the service modules
- `github_oidc`: repository/environment trust and plan/deploy roles

The `dev` and `prod` roots pass different availability, retention, and capacity values without duplicating service resource definitions.
