# Zero-cost local AWS simulation

This repository includes a reproducible local lab for exploring the platform without an AWS account, cloud credentials, or cloud spend. It exercises the API, container health, load balancing, multiple service replicas, PostgreSQL readiness, Terraform lifecycle, IAM roles, Secrets Manager metadata, log groups, and CloudWatch alarms.

It is a simulation, not evidence of an AWS deployment. Docker substitutes are used where the token-free LocalStack Community image does not implement the production service.

## Architecture

```text
                         Developer / CI runner
                                  |
                         http://127.0.0.1:8080
                                  |
                         +--------v--------+
                         | NGINX           |
                         | ALB analogue    |
                         +---+---------+---+
                             |         |
                    +--------v-+     +-v--------+
                    | Python   |     | Python   |
                    | API #1   |     | API #2   |
                    | ECS task |     | ECS task |
                    +----+-----+     +-----+-----+
                         |                 |
                         +--------+--------+
                                  |
                         +--------v--------+
                         | PostgreSQL 16   |
                         | RDS analogue    |
                         +-----------------+

       Terraform AWS provider
                 |
       http://127.0.0.1:4566
                 |
       +---------v----------------------------------------+
       | LocalStack Community                             |
       | IAM | S3/KMS | Secrets metadata | Logs | CloudWatch |
       +--------------------------------------------------+
```

## Service mapping and limits

| Production design | Local implementation | What is exercised |
|---|---|---|
| Application Load Balancer | NGINX on loopback port `8080` | Routing and health checks |
| ECS Fargate service | Two Docker Compose API replicas | Replica health, scaling, and replacement |
| Amazon ECR | Local Docker image store | Image build, immutable Git-SHA tag, and rollout |
| RDS PostgreSQL | PostgreSQL 16 container | Database availability and readiness dependency |
| IAM and KMS | LocalStack | ECS role definitions and encrypted-bucket configuration |
| Secrets Manager | LocalStack | Secret metadata only; no secret value is created |
| CloudWatch Logs and alarms | LocalStack | Log-group lifecycle and four alarm definitions |
| VPC/subnets/security groups | Docker's isolated bridge network | Private service connectivity, not AWS routing semantics |
| ECS Application Auto Scaling | `scale` command | Replica changes, not policy-driven AWS autoscaling |

LocalStack is pinned by tag and digest for deterministic, token-free tests. ECR, ECS, ELBv2, RDS, and Application Auto Scaling are deliberately represented by Docker components because those APIs are not available in the selected Community image. The real `dev` and `prod` Terraform roots remain the source of truth for AWS architecture.

## Requirements

- Docker Engine or Docker Desktop with Docker Compose v2
- Terraform 1.8 or newer
- AWS CLI v2
- `curl` and `jq`

No LocalStack auth token or real AWS credentials are required. The script exports the conventional LocalStack placeholders `test`/`test`; they are not usable AWS credentials.

## Start and verify

```bash
make local-up
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/ready
make local-status
```

`local-up` builds the API, starts all containers, applies `infra/environments/local`, and runs the integration checks. Terraform state and container volumes remain local and are ignored by Git.

## Terraform and deployment commands

```bash
make local-plan
make local-apply
make local-test
make local-deploy
make local-scale REPLICAS=3
make local-down
make local-reset
```

- `local-plan` verifies the simulated infrastructure is converged.
- `local-deploy` rebuilds the API, adds a `local-<git-sha>` image tag, replaces the API replicas, waits for health, and runs smoke tests.
- `local-scale` changes the replica count to demonstrate horizontal scaling.
- `local-down` preserves local data volumes.
- `local-reset` destroys the Terraform-managed simulation and removes its volumes.

## Security boundaries

- Host ports `4566` and `8080` bind only to `127.0.0.1`.
- PostgreSQL is not published to the host. Trust authentication is limited to the isolated Docker network and is strictly a local-test convenience.
- The API runs as a non-root user with a read-only root filesystem, no Linux capabilities, and `no-new-privileges`.
- The Secrets Manager resource contains metadata only. No password, token, API key, or AWS credential is stored.
- The local Terraform backend writes only beneath ignored `work/terraform/local/`.

## CI behavior

The `Local AWS simulation` workflow runs this lab on relevant pull requests and pushes. It has read-only repository permissions, does not request GitHub OIDC, and receives no AWS secrets. This gives reviewers an end-to-end local integration signal while the real AWS deployment workflows remain disabled by default.

## Troubleshooting

Inspect status and logs:

```bash
make local-status
docker compose -f compose.local.yml logs
```

If persisted emulator data is inconsistent after changing the resource model, run `make local-reset` and then `make local-up`. The reset affects only this Compose project's local state.
