.PHONY: test lint docker-build docker-smoke terraform-fmt terraform-validate security check \
	local-up local-plan local-apply local-test local-deploy local-status local-scale local-down local-reset

IMAGE_NAME ?= aws-production-platform:local

test:
	python -m pytest

lint:
	python -m ruff check app tests

docker-build:
	docker build --tag $(IMAGE_NAME) .

docker-smoke: docker-build
	bash scripts/docker-smoke-test.sh $(IMAGE_NAME)

terraform-fmt:
	terraform fmt -check -recursive infra

terraform-validate:
	bash scripts/terraform-validate.sh

security: docker-build
	docker run --rm $(IMAGE_NAME) python -c "import importlib.util; assert importlib.util.find_spec('setuptools') is None; assert importlib.util.find_spec('msgpack') is None"
	trivy image --ignorefile .trivyignore --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 $(IMAGE_NAME)
	trivy config --skip-check-update --severity HIGH,CRITICAL --exit-code 1 infra

check: lint test terraform-fmt terraform-validate docker-smoke security

local-up:
	bash scripts/local-lab.sh up

local-plan:
	bash scripts/local-lab.sh plan

local-apply:
	bash scripts/local-lab.sh apply

local-test:
	bash scripts/local-lab.sh test

local-deploy:
	bash scripts/local-lab.sh deploy

local-status:
	bash scripts/local-lab.sh status

local-scale:
	bash scripts/local-lab.sh scale $(REPLICAS)

local-down:
	bash scripts/local-lab.sh down

local-reset:
	bash scripts/local-lab.sh reset
