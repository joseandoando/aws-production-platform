# Contributing

Create a focused branch, make the smallest coherent change, and run `make check` before opening a pull request. Never commit `.env` files, Terraform state/plans, backend configuration, AWS credentials, database passwords, or generated task definitions.

For changes that affect the local integration path, also run `make local-up`, `make local-plan`, and `make local-test`. Stop the lab with `make local-down`, or remove all of its generated state with `make local-reset`.

Infrastructure changes should explain blast radius, expected plan, rollback, cost impact, and whether state migration is involved. Application changes should preserve `/health` as a dependency-free liveness check and `/ready` as the deployment readiness contract.
