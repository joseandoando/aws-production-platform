# CI/CD, deployment, and rollback

## Safety state

No AWS resources are deployed by this repository as delivered. Both AWS-backed workflow jobs require the repository variable `ENABLE_AWS_DEPLOYMENTS=true`; leave it absent until bootstrap and environment provisioning are complete.

## Prerequisites

- Terraform 1.8 or newer, Docker, AWS CLI v2, GitHub CLI, `jq`, and `curl`
- An AWS administrator identity for the one-time bootstrap and initial environment apply
- A GitHub repository where `dev` and `prod` environments can be configured
- A cost review and AWS Budget before provisioning

AWS access keys must not be added to GitHub. Local bootstrap authentication should use AWS IAM Identity Center or another approved short-lived session.

## 1. Bootstrap state and OIDC

```bash
cp infra/bootstrap/terraform.tfvars.example infra/bootstrap/terraform.tfvars
# Edit the bucket name and GitHub owner.
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
```

The bootstrap state begins locally and is ignored by Git. After the bucket exists, copy `infra/bootstrap/backend.tf.example` to `backend.tf`, fill in the bucket, and run `terraform init -migrate-state`; retain controlled recovery access to this foundational state.

Create the GitHub environments, set production reviewers, and add these environment variables:

| Variable | Source |
|---|---|
| `AWS_REGION` | Chosen deployment region |
| `AWS_TERRAFORM_ROLE_ARN` | Bootstrap output |
| `AWS_DEPLOY_ROLE_ARN` | Bootstrap output |
| `TF_STATE_BUCKET` | Bootstrap output |
| `TF_STATE_KMS_KEY_ARN` | Bootstrap output |

These identifiers are not credentials. GitHub receives temporary AWS credentials only after OIDC trust evaluation.

## 2. Initialize an environment

```bash
cp infra/environments/dev/backend.hcl.example infra/environments/dev/backend.hcl
cp infra/environments/dev/terraform.tfvars.example infra/environments/dev/terraform.tfvars
terraform -chdir=infra/environments/dev init -backend-config=backend.hcl
terraform -chdir=infra/environments/dev plan
```

Review the plan, especially NAT gateway count, RDS availability, deletion protection, and estimated cost.

## 3. Seed the first image

The ECS service points at the ECR tag `bootstrap`, so seed that tag before the first full apply:

```bash
terraform -chdir=infra/environments/dev apply -target=module.platform.module.ecr
repository_name="aws-production-platform-dev"
account_id="$(aws sts get-caller-identity --query Account --output text)"
region="$(aws configure get region)"
aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com"
docker build -t "${account_id}.dkr.ecr.${region}.amazonaws.com/${repository_name}:bootstrap" .
docker push "${account_id}.dkr.ecr.${region}.amazonaws.com/${repository_name}:bootstrap"
```

Then create and review a complete plan before applying it:

```bash
terraform -chdir=infra/environments/dev plan -out=dev.tfplan
terraform -chdir=infra/environments/dev apply dev.tfplan
terraform -chdir=infra/environments/dev output -json > /tmp/dev-output.json
bash scripts/configure-github-environment.sh dev /tmp/dev-output.json
```

Repeat deliberately for prod, using its own backend and variables. Production should have an ACM certificate and SNS alarm topic configured before launch.

## 4. Enable automation

After infrastructure exists and GitHub environment variables are verified, set the repository variable:

```bash
gh variable set ENABLE_AWS_DEPLOYMENTS --body true
```

The Terraform workflow will now create AWS-backed plans. The deployment workflow sends pushes to `main` to dev; production is selected manually with `workflow_dispatch` and should require environment approval.

## Release behavior

The deployment job builds `sha-<12-character-commit>`, pushes it to ECR, clones the active task definition, replaces only the named container image, registers a revision, updates ECS, waits for stability, then smoke-tests `/health` and `/ready`. It never writes AWS keys or database credentials.

## Rollback

ECS circuit breaking automatically rolls back deployments that cannot reach steady state. A successful but functionally bad release requires operator rollback:

```bash
cluster="aws-production-platform-prod"
service="aws-production-platform-prod"
aws ecs describe-services --cluster "${cluster}" --services "${service}" \
  --query 'services[0].deployments[].taskDefinition' --output table

# Select a known-good prior task definition ARN.
aws ecs update-service --cluster "${cluster}" --service "${service}" \
  --task-definition "<known-good-task-definition-arn>"
aws ecs wait services-stable --cluster "${cluster}" --services "${service}"
bash scripts/smoke-test.sh "<application-url>"
```

Alternatively, manually dispatch the deployment workflow with an existing known-good immutable ECR tag. Record the incident timeline and preserve the failed revision for analysis. Do not use `latest` or overwrite an existing tag.
