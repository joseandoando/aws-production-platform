# Production improvements

## Priority 0: launch blockers

- Require ACM TLS, a Route 53 record, and HTTPS-only application access.
- Route every alarm to a tested on-call destination and add composite availability alarms.
- Create AWS Budgets, cost anomaly detection, CloudTrail, GuardDuty, Security Hub, and AWS Config baselines.
- Separate dev and prod into AWS accounts with organization SCPs and distinct OIDC roles.
- Integrate the application with PostgreSQL using a least-privilege database user, secret rotation, migrations, connection pooling, and RDS Proxy.
- Add AWS WAF managed rules, request-rate protection, ALB access logs, and a retention policy.
- Run load, rollback, RDS restore, and AZ-failure tests before accepting traffic.

## Priority 1: delivery and supply chain

- Add automated provenance verification for the GitHub Actions already pinned to reviewed commit SHAs.
- Generate an SBOM, scan source/IaC/images, sign images with keyless signing, and verify signatures at admission/deployment time.
- Add Checkov/tfsec, TFLint, actionlint, Hadolint, and policy-as-code gates.
- Promote the exact same image digest from dev to prod instead of rebuilding.
- Add canary or blue/green delivery with automatic metric-based rollback.
- Require reviewed Terraform plans and move applies into a dedicated, approval-protected workflow.

## Priority 2: resilience and observability

- Add service-level objectives for availability and latency with burn-rate alerts.
- Emit structured JSON logs, request IDs, latency/error metrics, and OpenTelemetry traces.
- Use VPC endpoints to reduce NAT dependency and restrict task egress.
- Encrypt logs, ECR, RDS, S3 state, and Secrets Manager with scoped customer-managed KMS keys where compliance requires it.
- Add RDS enhanced monitoring, alarms for storage/connections/replica lag, and tested point-in-time recovery.
- Evaluate Aurora PostgreSQL, read replicas, or multi-region recovery only against measured requirements.

## Priority 3: platform experience

- Publish reusable versioned Terraform modules with automated module tests.
- Add ephemeral preview environments with quotas and automatic cleanup.
- Provide golden-path service templates, runbooks, dashboards, and ownership metadata.
- Track DORA metrics, deployment health, toil, error budgets, and cost per service.
