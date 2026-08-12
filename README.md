# AWS Production Platform

[![Application CI](https://github.com/joseandoando/aws-production-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/joseandoando/aws-production-platform/actions/workflows/ci.yml)
[![Terraform CI](https://github.com/joseandoando/aws-production-platform/actions/workflows/terraform.yml/badge.svg)](https://github.com/joseandoando/aws-production-platform/actions/workflows/terraform.yml)
[![Local AWS simulation](https://github.com/joseandoando/aws-production-platform/actions/workflows/local-lab.yml/badge.svg)](https://github.com/joseandoando/aws-production-platform/actions/workflows/local-lab.yml)

A production-oriented AWS reference platform built to demonstrate practical DevOps, Site Reliability Engineering, and cloud engineering skills: modular infrastructure as code, private networking, identity federation, immutable container delivery, health-based rollouts, autoscaling, monitoring, and operational documentation.

> **Deployment status:** the repository contains tested implementation code, but no AWS infrastructure has been deployed from this project. AWS deployment workflows are disabled by default to prevent accidental spend.

## What this project demonstrates

- Modular Terraform with independent `dev` and `prod` roots
- A three-tier VPC across multiple Availability Zones
- ECS Fargate tasks in private subnets behind an Application Load Balancer
- RDS PostgreSQL in isolated database subnets with RDS-managed credentials in Secrets Manager
- ECR image scanning, immutable tags, and lifecycle retention
- ECS target-tracking autoscaling on CPU and memory
- CloudWatch logs, Container Insights, and actionable service/ALB alarms
- GitHub Actions authentication through OIDC—no long-lived AWS access keys
- Immutable image deployment, ECS stability waiting, smoke testing, and documented rollback
- A non-root, read-only-container Python API with liveness and readiness endpoints
- A zero-cost local integration lab using LocalStack, Docker Compose, NGINX, and PostgreSQL

## Architecture

```text
                         GitHub
                  Actions + OIDC token
                           |
                           v
                    AWS IAM roles
                  (plan / deployment)
                           |
          +----------------+----------------+
          |                                 |
          v                                 v
     Amazon ECR                       Terraform state
  immutable images                  S3 + native locking
          |
          | image pull
          v
+------------------------------------------------------------------+
| AWS Region                                                       |
|                                                                  |
|  +-------------------------- VPC ------------------------------+  |
|  |                                                            |  |
|  |  Public subnets (AZ-a / AZ-b)                              |  |
|  |  Internet --> ALB --> target group                         |  |
|  |                 |                                          |  |
|  |                 v                                          |  |
|  |  Private app subnets (AZ-a / AZ-b)                         |  |
|  |       ECS Fargate service (API tasks, no public IPs)       |  |
|  |          |            |                 |                  |  |
|  |          |            +--> CloudWatch logs/alarms          |  |
|  |          +--> NAT gateway(s) --> AWS APIs / ECR            |  |
|  |          |                                                 |  |
|  |          v                                                 |  |
|  |  Isolated database subnets (AZ-a / AZ-b)                   |  |
|  |       RDS PostgreSQL + Secrets Manager credential          |  |
|  |                                                            |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

Production uses a NAT gateway per AZ, two baseline tasks, Multi-AZ RDS, 30-day database backups, deletion protection, and 90-day application log retention. Development uses deliberately smaller, less redundant resources to control portfolio costs.

## API

| Endpoint | Purpose | Expected response |
|---|---|---|
| `GET /` | Service metadata | `200` with service, environment, and timestamp |
| `GET /health` | Liveness for Docker, ECS, and ALB | `200` while the process can serve requests |
| `GET /ready` | Readiness for post-deployment smoke tests | `200` when the optional dependency check passes |

Run it locally:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
python -m pytest
docker build -t aws-production-platform:local .
bash scripts/docker-smoke-test.sh aws-production-platform:local
```

## Zero-cost local AWS lab

Run an end-to-end simulation without an AWS account, real cloud credentials, or LocalStack auth token:

```bash
make local-up
curl http://127.0.0.1:8080/ready
make local-status
```

The lab uses LocalStack Community for IAM, S3/KMS, Secrets Manager metadata, CloudWatch Logs, and alarms. Docker Compose provides two API replicas as ECS/Fargate analogues, NGINX as the ALB analogue, the local Docker image store as ECR, and PostgreSQL as RDS. `make local-up` applies a separate local Terraform root and runs integration checks automatically.

This is intentionally described as a **simulation**: it validates application and infrastructure workflows locally, but it does not reproduce AWS networking or prove that the real AWS platform has been deployed. See the [local lab architecture, commands, security boundaries, and limitations](docs/local-development.md).

## Repository layout

```text
app/                         Flask API
tests/                       Endpoint tests
infra/bootstrap/             State bucket and GitHub OIDC IAM roles
infra/environments/dev/      Development Terraform root
infra/environments/local/    Token-free LocalStack Terraform root
infra/environments/prod/     Production Terraform root
infra/modules/               Network, ECR, ECS, RDS, platform, and OIDC modules
.github/workflows/           Application CI, Terraform CI/plan, and ECS deployment
local/                       NGINX load-balancer configuration for the local lab
scripts/                     Validation, local automation, configuration, and smoke tests
docs/                        Architecture, security, delivery, cost, and operations guides
```

## CI/CD at a glance

Pull requests and pushes run Python lint/tests, a Docker build and container smoke test, `terraform fmt`, `terraform validate`, and the zero-cost local AWS simulation. AWS-backed plans and deployments remain skipped until `ENABLE_AWS_DEPLOYMENTS=true` is intentionally configured.

When enabled, a deployment:

1. Exchanges GitHub's short-lived OIDC token for a scoped AWS role.
2. Builds the image and tags it with `sha-<commit>`.
3. Pushes the immutable tag to ECR.
4. Copies the active ECS task definition and changes only the API image.
5. Registers a new revision and updates the service.
6. Waits for ECS service stability; the deployment circuit breaker can roll back failed starts.
7. Calls `/health` and `/ready` through the ALB.

Production is a manually selected GitHub environment and should be configured with required reviewers. See [deployment and rollback](docs/deployment.md).

## Reliability and security choices

- Tasks and PostgreSQL have no public IP addresses.
- Security groups allow ALB-to-task and task-to-database traffic only on application ports.
- RDS generates and rotates ownership of the master password through Secrets Manager; no password enters Terraform variables or GitHub.
- GitHub trust is restricted to this repository's `dev` and `prod` environment subjects.
- The deployment role can push only to project ECR repositories and pass only project ECS roles.
- Containers run as UID `10001`, use a read-only root filesystem in ECS, and expose no shell-based management path.
- ECS deployment circuit breaking, health checks, minimum healthy percentage, and post-rollout smoke tests constrain release risk.

See the full [security rationale](docs/security.md), [architecture and networking](docs/architecture.md), and [monitoring and incident response guide](docs/operations.md).

## Estimated cost

Illustrative `us-east-1` on-demand cost at low traffic is roughly **$90–130/month for dev** and **$250–350/month for prod**. NAT gateways, the ALB, and RDS dominate the baseline; traffic, logs, backups, public IPv4, and taxes can increase it. These are planning ranges—not quotes—and should be recalculated before deployment. See [cost assumptions and optimization options](docs/costs.md).

The local simulation has no AWS service charge; it uses only the developer machine or CI runner.

## Production improvements

Before using this as a real production platform, add a custom domain and mandatory TLS, WAF, VPC endpoints, centralized alert routing, RDS proxy and application database integration, cross-account environment isolation, AWS Config/GuardDuty/Security Hub, load and recovery testing, and policy-as-code scanning. The prioritized roadmap is in [production improvements](docs/production-improvements.md).

## Documentation

- [Architecture and networking](docs/architecture.md)
- [Deployment, CI/CD, and rollback](docs/deployment.md)
- [Security decisions](docs/security.md)
- [Monitoring and incident response](docs/operations.md)
- [Estimated AWS costs](docs/costs.md)
- [Production improvements](docs/production-improvements.md)
- [Zero-cost local AWS simulation](docs/local-development.md)
- [Contributing](CONTRIBUTING.md) and [security reporting](SECURITY.md)

## License

MIT — see [LICENSE](LICENSE).
