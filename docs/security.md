# Security decisions

## Identity and credentials

GitHub Actions uses IAM OIDC federation. Trust requires the `sts.amazonaws.com` audience and a subject matching this repository's `dev` or `prod` GitHub environment. No AWS access-key secret is expected or supported by the workflows.

The Terraform plan role combines AWS read-only discovery with state-object access. The deployment role is separate: it can authenticate to ECR, upload only to project repositories, register task definitions, update ECS, and pass only project-prefixed ECS roles. This separation prevents an application release job from changing the network or database.

The one-time bootstrap/application operator remains high privilege and should use an IAM Identity Center session, MFA, and a dedicated administrative role. For a real organization, move dev and prod into separate AWS accounts and use a central deployment account.

## Secrets

RDS sets `manage_master_user_password = true`; AWS generates and stores the credential in Secrets Manager. Passwords are not accepted as Terraform inputs. The sample API does not need a database connection, so it is not granted secret access. A future data-aware service should grant `secretsmanager:GetSecretValue` only for the environment's secret ARN and should support credential rotation.

The `.gitignore` excludes environment files, Terraform state, plans, local backend configuration, and `.env` files. Terraform state can still contain sensitive metadata and must remain in the versioned, encrypted, public-blocked S3 backend.

## Network and workload hardening

- Only the ALB is public; task and database interfaces are private.
- Database ingress is security-group-referenced rather than CIDR-based.
- RDS storage is encrypted and SSL is forced.
- ECR rejects tag mutation, scans on push, and expires old images.
- ECS uses separate execution and task roles; the application task role has no AWS permissions.
- The container uses a non-root UID and a read-only root filesystem.
- ALB invalid HTTP header fields are dropped.

## Deliberate gaps

HTTP remains available in development when no ACM certificate is supplied; production requires an ACM certificate. Task egress permits HTTPS through NAT plus VPC DNS and PostgreSQL; use VPC endpoints and destination filtering for stricter environments. The design does not yet include WAF, Shield Advanced, GuardDuty, Security Hub, AWS Config, application-data customer-managed keys, image signature verification, SBOM generation, or policy-as-code gates.

## Secret scanning and response

Enable GitHub secret scanning and push protection where the account plan permits it. If a credential is ever committed:

1. Revoke or rotate it immediately; deleting Git history is not sufficient.
2. Review CloudTrail and provider audit logs from the earliest possible exposure.
3. Contain affected roles/resources and create replacement credentials.
4. Remove the value from current and historical Git data using an approved history-rewrite process.
5. Document scope, timeline, root cause, and preventive action.
