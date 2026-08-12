# Contributing

Create a focused branch, make the smallest coherent change, and run `make check` before opening a pull request. Never commit `.env` files, Terraform state/plans, backend configuration, AWS credentials, database passwords, or generated task definitions.

Infrastructure changes should explain blast radius, expected plan, rollback, cost impact, and whether state migration is involved. Application changes should preserve `/health` as a dependency-free liveness check and `/ready` as the deployment readiness contract.

